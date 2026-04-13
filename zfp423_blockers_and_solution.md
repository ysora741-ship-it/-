# 未完成根因分析与解决方案：Zfp423 转录本公共 RNA-seq 分析

## 1) 为什么上次没有完成

### A. 工具链缺失（直接阻断）
上次运行环境没有 RNA-seq 定量所需核心工具（如 `salmon` / `kallisto` / `STAR` / `samtools` / `fasterq-dump`），导致无法执行：
1. 原始 FASTQ 下载与解包
2. 全转录组索引构建
3. 样本级转录本定量
4. junction/unique region 支持证据计数

### B. 任务规模与数据吞吐未做收敛
目标覆盖组织谱 + 两个成脂时序（含重复和多个时间点），属于多项目整合任务。上次没有先做“最小可完成批次（MVP）”，导致无法在单次执行中产出可信结果。

### C. 元数据标准化流程缺失
未先构建统一 manifest（run 与时间点/处理条件映射规则），会直接影响：
- 是否可比（标准诱导 vs 药物/vehicle/water 干预）
- 是否可汇总（时间点命名与重复定义不一致）

### D. 异构体可区分证据策略未前置
Zfp423 两个转录本的可靠区分依赖 informative reads（unique junction 或 unique exon region）。上次没有把该检查置于前置 QC，导致即使做出 TPM 也可能不可解释。

---

## 2) 可执行的修复方案（按优先级）

## Phase 0：环境与工具准备（先打通）
建议至少准备以下工具：
- 下载：`sra-tools` 或 ENA 直连下载（优先 ENA）
- 定量：`salmon`（推荐，速度快）
- 比对与 junction：`STAR` + `samtools`
- 元数据处理：`python` + `pandas`

建议固定版本并记录到 `env/README.md`，避免重跑漂移。

## Phase 1：先完成 MVP（小批次闭环）
先只做以下最小集合，验证方法可行：
- 组织：Brain + BAT（各 ≥2 runs）
- C3H10：D0/D2/D4/D6（各 ≥2 runs）
- 3T3-L1：D0/D1/D2/D4/D7（各 ≥2 runs）

每个 run 都输出：
- `count_SZfp423`, `count_LZfp423`
- `RPM_*`, `TPM_*`
- `total_Zfp423`, `frac_SZfp423`, `frac_LZfp423`

## Phase 2：扩展到完整目标
在 MVP 通过后再加入：
- iWAT/SCAT、gWAT/GAT 全部候选 runs
- C3H10 D1/D3/D8
- 3T3-L1 额外重复
- 排除非标准诱导/特殊处理，或独立分层分析

## Phase 3：junction/unique region 证据
- 依据 GTF 确定 SZfp423 / LZfp423 的唯一剪接位点与唯一外显子区域
- STAR 比对后用 junction 计数（SJ.out.tab）+ 区域覆盖计数
- 若 informative reads < 10（可调整阈值），标注 `evidence_weak`

---

## 3) 数据与统计判读标准（防止过度解读）

1. **先看总量再看比例**：
   - `total_Zfp423` 显著下降时，比例变化可能是组成效应。
2. **比例结论需证据门槛**：
   - informative reads 太低仅可报告“趋势”，不得下“切换”结论。
3. **时间序列要分处理条件**：
   - 标准 MDI 诱导与药物处理不应混合求均值。
4. **跨项目仅作方向比较**：
   - 不同实验批次不直接做绝对值比较，优先项目内标准化。

---

## 4) 建议的目录与产物约定

- `data/manifest/zfp423_manifest_used.csv`
- `results/zfp423_quant_per_sample.csv`
- `results/zfp423_tissue_summary.csv`
- `results/zfp423_C3H10_timeseries.csv`
- `results/zfp423_3T3_timeseries.csv`
- `results/zfp423_junction_support.csv`
- `results/zfp423_qc_summary.csv`
- `results/figures/*.png`
- `results/zfp423_final_report.md`

---

## 5) 本次整改产出
1. 提供了本“根因+修复”文档。
2. 明确了分阶段交付策略，先 MVP 再扩展，避免再次“全空结果”。
3. 给出 junction/unique region 的证据阈值与解释边界。


## 6) 本地环境实测（2026-04-13）
已执行 `scripts/zfp423_phase0_preflight.sh`，结果写入 `zfp423_phase0_preflight_report.txt`。
关键发现：
- 关键工具全部缺失：`salmon/kallisto/STAR/samtools/fasterq-dump/prefetch`。
- 外网访问受限：到 SRA/NCBI 端点请求失败（HTTP_000 或经代理拒绝）。
- `apt-get update` 失败（HTTP 403），因此无法在当前环境安装所需工具。

这解释了为什么无法直接进入 Phase 1 产出“真实 run + 真实 TPM/比例 + junction 证据”。

## 7) 解封后可立即执行的最短路径
1. 在可联网环境（或已预装工具镜像）运行 `scripts/zfp423_phase0_preflight.sh`，确认 `preflight_status` 不再是 `blocked`。
2. 准备 MVP manifest（Brain/BAT + C3H10 D0/D2/D4/D6 + 3T3-L1 D0/D1/D2/D4/D7）。
3. 准备完整小鼠转录组 FASTA + GTF（禁止 mini-reference）。
4. 执行：
   - `scripts/zfp423_phase1_mvp.sh <manifest.csv> <annotation.gtf> <transcripts.fa> <outdir>`
5. 产出后补跑 junction/unique region 计数并回填 `zfp423_junction_support.csv`，再按 evidence 强弱打标。
