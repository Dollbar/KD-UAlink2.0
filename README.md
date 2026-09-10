# KD-UAlink2.0

UALink Endpoint / Controller 与 Switch 数字 RTL 研发工程，目标为 Common 2.0 与 200G DL/PL 2.0，面向 TSMC 28 nm ASIC 流程。当前处于分层 RTL 集成阶段，尚未形成完整可交付 IP，也未完成全顶层工艺时序收敛。

## 工程结构

| 目录 | 内容 |
|---|---|
| `rtl/{upli,dl,tl,phy}` | 当前工作 RTL 与各层依赖 |
| `model/ualink` | UPLI、DL 与配置参考模型 |
| `model/{tl,phy}` | TL 信用/字段/存储与 RS 参考模型 |
| `verification/` | 模型、真实 RTL、双端通信、形式验证与工具测试 |
| `scripts/` | 综合、时序、等价检查、Make 片段和清理入口 |
| `config/` | 接口契约、参数矩阵、工具配置、源码来源 |
| `docs/` | 当前进度、架构、规范待确认项与后续计划 |
| `variants/rs_qualified` | 显式选择的 RS 资格判定候选；不与默认 RTL 混合编译 |
| `specs/`, `third_party/` | 需求映射和外部依赖登记 |
| `build/`, `reports/` | 可删除、可再生成的输出，不入库 |

## 使用

需要 Python 3.10+、Icarus Verilog（`iverilog`/`vvp`）、Verilator、C++ 编译器和 Make；综合/形式验证使用 Yosys，时序使用 OpenSTA。已使用的工具版本见 `config/toolchain.json`。

```sh
make test
make rtl-smoke
make sram-smoke KD28_ROOT=/path/to/authorized/Overflow
make clean-dry-run
make clean
```

- `test`：原有模型与工具测试，以及 TL 发布/消费释放模型测试。
- `rtl-smoke`：信用发布器、实际接收端、TL 端口、双 TL 端及一个 RS 配置；输出在 `build/verification/` 及 `build/`。
- `sram-smoke`：实际 TL 接收 SRAM 六配置和含错误注入的 DL 双端重放，随后逐周期独立核对；需要显式提供外部依赖。
- `clean`：删除本工程 `build/`、`reports/`、`artifacts/` 和 Python 缓存，不删除规范私有目录或外部依赖。

每个 RTL 脚本也可单独运行，使用 `--help` 查看参数。重复运行同名回归前执行 `make clean`；脚本拒绝覆盖已有的部分运行目录。已有 UPLI 单模块入口保留，例如 `make sim-connection`，其工艺分析需显式提供 `LIB_ROOT`。

## 当前状态

信用发布器已通过 8 配置、147,457 个真实时钟沿；实际接收 SRAM 已通过 6 配置、6,750 沿。新增实际接收 FIFO 到 FC 的双端组合已通过 16 配置、5,412 周期；小 Data 信用下已复现中途停顿，持续前进性仍待修复。当前顶层没有工艺 STA 通过结论。

详细范围、历史成绩的适用边界和下一步见 [工程状态](docs/status.md)。旧运行日志、波形、生成网表及证明缓存按工作区整理要求清理；保留的历史数字是状态摘要，不能替代已删除的原始证明档案。

## 外部输入

规范正文、PDK/Liberty、SRAM 模型、SerDes/VIP 和本地主机配置不随本仓库分发。`KD28_ROOT` 指向有权使用的外部仓库，其文件清单及校验值见 [依赖登记](third_party/kd28_dependency.json)。`specs/private/`、`third_party/private/` 与 `config/local.json` 被忽略。源码许可证尚未指定。

当前新增整段发送准入及实际双端 SRAM 回归见 [准入阶段审查](docs/tl_credit_admission_review.md)。总容量足够的连续多 Beat 压力反例已修复；超容量事务处理、完整调度证明和工艺 STA 仍开放。

实际半Flit打包与双端验证见 [打包阶段审查](docs/tl_tx_packer_review.md)：已接入旧尾部／新头部／FC选择和独立输入确认，完整事务调度及超容量处理仍在推进。
