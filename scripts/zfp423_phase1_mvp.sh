#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   scripts/zfp423_phase1_mvp.sh <manifest_csv> <gtf> <transcript_fasta> <outdir>
# manifest columns required:
# accession,run,model_or_tissue,timepoint,condition,fastq_1,fastq_2,layout

manifest=${1:-}
gtf=${2:-}
fa=${3:-}
outdir=${4:-results_mvp}

if [[ -z "$manifest" || -z "$gtf" || -z "$fa" ]]; then
  echo "Usage: $0 <manifest_csv> <gtf> <transcript_fasta> <outdir>"
  exit 1
fi

mkdir -p "$outdir"/quant "$outdir"/logs "$outdir"/junction

for t in salmon python; do
  command -v "$t" >/dev/null 2>&1 || { echo "Missing required tool: $t"; exit 2; }
done

# 1) index (full transcriptome; never mini-reference)
if [[ ! -d "$outdir/salmon_index" ]]; then
  salmon index -t "$fa" -i "$outdir/salmon_index" -k 31 | tee "$outdir/logs/salmon_index.log"
fi

# 2) per-sample quant
awk -F, 'NR>1{print}' "$manifest" | while IFS=, read -r accession run model timepoint condition fq1 fq2 layout; do
  sample_out="$outdir/quant/$run"
  mkdir -p "$sample_out"
  if [[ "$layout" == "PAIRED" ]]; then
    salmon quant -i "$outdir/salmon_index" -l A -1 "$fq1" -2 "$fq2" \
      --validateMappings --gcBias --seqBias -o "$sample_out" \
      | tee "$outdir/logs/${run}.salmon.log"
  else
    salmon quant -i "$outdir/salmon_index" -l A -r "$fq1" \
      --validateMappings --gcBias --seqBias -o "$sample_out" \
      | tee "$outdir/logs/${run}.salmon.log"
  fi
done

# 3) extract two isoforms and compute requested metrics (count/RPM/TPM/frac)
OUTDIR="$outdir" MANIFEST="$manifest" python - <<'PY'
import csv,glob,os

outdir=os.environ['OUTDIR']
manifest=os.environ['MANIFEST']
qfiles=glob.glob(f"{outdir}/quant/*/quant.sf")
meta={}
with open(manifest) as f:
    r=csv.DictReader(f)
    for row in r:
        meta[row['run']]=row

SZ='NM_001310520.1'
LZ='NM_033327.2'
rows=[]
for q in qfiles:
    run=os.path.basename(os.path.dirname(q))
    d={SZ:{'NumReads':0.0,'TPM':0.0},LZ:{'NumReads':0.0,'TPM':0.0}}
    total_reads=0.0
    with open(q) as f:
        r=csv.DictReader(f, delimiter='\t')
        for row in r:
            nr=float(row['NumReads'])
            total_reads += nr
            if row['Name'] in d:
                d[row['Name']]={'NumReads':nr,'TPM':float(row['TPM'])}
    csz=d[SZ]['NumReads']; clz=d[LZ]['NumReads']
    tpm_sz=d[SZ]['TPM']; tpm_lz=d[LZ]['TPM']
    rpm_sz=(csz/total_reads*1e6) if total_reads>0 else 0.0
    rpm_lz=(clz/total_reads*1e6) if total_reads>0 else 0.0
    total=csz+clz
    frac_sz=(csz/total) if total>0 else 0.0
    frac_lz=(clz/total) if total>0 else 0.0
    m=meta.get(run,{})
    rows.append({
      'accession':m.get('accession','NA'),'run':run,
      'model_or_tissue':m.get('model_or_tissue','NA'),'timepoint':m.get('timepoint','NA'),'condition':m.get('condition','NA'),
      'count_SZfp423':f"{csz:.3f}",'count_LZfp423':f"{clz:.3f}",
      'RPM_SZfp423':f"{rpm_sz:.6f}",'RPM_LZfp423':f"{rpm_lz:.6f}",
      'TPM_SZfp423':f"{tpm_sz:.6f}",'TPM_LZfp423':f"{tpm_lz:.6f}",
      'total_Zfp423':f"{total:.3f}",'frac_SZfp423':f"{frac_sz:.6f}",'frac_LZfp423':f"{frac_lz:.6f}",
      'evidence_flag':'pending_junction_qc'})

fields=['accession','run','model_or_tissue','timepoint','condition','count_SZfp423','count_LZfp423','RPM_SZfp423','RPM_LZfp423','TPM_SZfp423','TPM_LZfp423','total_Zfp423','frac_SZfp423','frac_LZfp423','evidence_flag']
with open(f"{outdir}/zfp423_quant_per_sample.csv",'w',newline='') as f:
    w=csv.DictWriter(f,fieldnames=fields); w.writeheader(); w.writerows(rows)
print(f"Wrote {outdir}/zfp423_quant_per_sample.csv with {len(rows)} rows")
PY

echo "Phase 1 quant complete. Next: run STAR junction workflow for isoform-discriminating evidence."
