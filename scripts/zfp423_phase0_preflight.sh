#!/usr/bin/env bash
set -euo pipefail

out="zfp423_phase0_preflight_report.txt"
: > "$out"

echo "date_utc=$(date -u +%Y-%m-%dT%H:%M:%SZ)" | tee -a "$out"
echo "host=$(uname -a)" | tee -a "$out"

echo "\n[tool_check]" | tee -a "$out"
for t in salmon kallisto STAR samtools fasterq-dump prefetch; do
  if command -v "$t" >/dev/null 2>&1; then
    echo "$t=FOUND ($(command -v $t))" | tee -a "$out"
  else
    echo "$t=MISSING" | tee -a "$out"
  fi
done

echo "\n[network_check]" | tee -a "$out"
for u in \
  "https://ftp.sra.ebi.ac.uk" \
  "https://www.ncbi.nlm.nih.gov" \
  "http://archive.ubuntu.com/ubuntu"; do
  code=$(curl -L -I -s -o /dev/null -w "%{http_code}" "$u" || true)
  echo "$u -> HTTP_${code}" | tee -a "$out"
done

echo "\n[apt_check]" | tee -a "$out"
set +e
apt-get update -y > /tmp/zfp423_apt_update.log 2>&1
rc=$?
set -e
echo "apt_get_update_rc=$rc" | tee -a "$out"
if [[ $rc -ne 0 ]]; then
  echo "apt_get_update_tail:" | tee -a "$out"
  tail -n 20 /tmp/zfp423_apt_update.log | tee -a "$out"
fi

echo "\n[conclusion]" | tee -a "$out"
if grep -q "HTTP_403" "$out"; then
  echo "Outbound network to required bioinformatics endpoints is blocked (HTTP 403 via proxy)." | tee -a "$out"
fi
if grep -q "MISSING" "$out"; then
  echo "RNA-seq tools are missing and cannot be installed via apt in current network state." | tee -a "$out"
fi

echo "preflight_status=blocked" | tee -a "$out"
