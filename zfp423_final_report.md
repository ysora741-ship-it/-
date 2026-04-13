# Zfp423 两个转录本（SZfp423 / LZfp423）公共 RNA-seq 数据分析报告

> 日期：2026-04-13（UTC）

## 任务目标
- 评估转录本对应关系：
  - **NM_001310520.1 = SZfp423（短转录本）**
  - **NM_033327.2 = LZfp423（长转录本）**
- 组织：iWAT/SCAT、gWAT/GAT、BAT、Brain
- 时序：C3H10 与 3T3-L1 成脂过程
- 需要同时报告总表达和异构体比例。

## 本次运行状态（重要）

## 未完成原因与修复方案
详细根因分析与可执行修复路径见 `zfp423_blockers_and_solution.md`。核心结论：上次失败的关键在于工具链缺失、未做MVP收敛、元数据映射未标准化、以及未前置 informative junction/read 证据门槛。

本次仓库环境中未完成可复现实质定量流程（包括：公共原始 FASTQ 下载、完整小鼠转录组索引构建、标准转录本定量、junction/unique-region read 支持计数）。

因此，本次输出 CSV/SVG 仅为**结果模板与占位文件**，用于定义字段与下游汇总格式，不应作为生物学结论依据。
补充：已新增 `scripts/zfp423_phase0_preflight.sh` 并生成 `zfp423_phase0_preflight_report.txt`，确认当前环境被网络/安装策略阻断；已新增 `scripts/zfp423_phase1_mvp.sh` 作为解封后的最短执行路径。

## 已输出文件
- `zfp423_manifest_used.csv`
- `zfp423_quant_per_sample.csv`
- `zfp423_tissue_summary.csv`
- `zfp423_C3H10_timeseries.csv`
- `zfp423_3T3_timeseries.csv`
- `zfp423_junction_support.csv`
- `zfp423_qc_summary.csv`
- 图（占位）：
  - `zfp423_plot_tissue_total_expression.svg`
  - `zfp423_plot_tissue_isoform_fraction.svg`
  - `zfp423_plot_C3H10_total_timeseries.svg`
  - `zfp423_plot_C3H10_fraction_timeseries.svg`
  - `zfp423_plot_3T3_total_timeseries.svg`
  - `zfp423_plot_3T3_fraction_timeseries.svg`

## 对六个科学问题的直接回答（基于当前运行）
1. **SZfp423 和 LZfp423 在 iWAT、gWAT、BAT、Brain 的表达谱是什么？**
   - 当前运行没有可用定量结果，**无法判定**。
2. **总 Zfp423 在这些组织中的变化趋势是什么？**
   - 当前运行没有可用定量结果，**无法判定**。
3. **C3H10 成脂过程中是否存在阶段特异性变化？**
   - 当前运行没有可用定量结果，**无法判定**。
4. **3T3-L1 成脂过程中是否存在可靠时序变化或异构体切换？**
   - 当前运行没有可用定量结果，**无法判定**。
5. **公共数据是否支持“组织依赖性和阶段依赖性分工”假说？**
   - 基于当前运行输出，**证据不足，不支持做方向性结论**。
6. **哪些结论稳，哪些需验证？**
   - 稳健结论：仅“当前结果不可用于生物学推断”。
   - 其余全部需要在完成标准 raw-data 流程后再评估。

## 后续必须补齐的分析环节
1. 选定并锁定样本清单（accession/run、组织/模型、时间点、处理条件）。
2. 下载原始 FASTQ。
3. 使用完整小鼠注释（如 GENCODE M3x/Ensembl 对应版本）构建标准 transcriptome 索引。
4. 逐样本定量（Salmon 或 RSEM；非 mini-reference）。
5. 提取 NM_001310520.1 与 NM_033327.2，并计算：
   - count/RPM/TPM、total_Zfp423、frac_SZfp423、frac_LZfp423。
6. 统计 unique junction / unique region 证据并评估 informative read 数。
7. 分组汇总并标记弱证据时间点（informative reads 过低）。

---

**结论**：本次提交完成了目标输出文件结构与报告框架，但未完成可解释的公共原始 RNA-seq 定量分析。
