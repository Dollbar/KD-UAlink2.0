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

每个 RTL 脚本也可单独运行，使用 `--help` 查看参数。保留验证证据时，请使用新的 `--label` 或干净导出副本；部分脚本拒绝覆盖已有目录。`make clean` 会删除本地验证结果。已有 UPLI 单模块入口保留，例如 `make sim-connection`，其工艺分析需显式提供 `LIB_ROOT`。

## 当前状态

实际 TL 链路已接入接收 SRAM 退休、信用发布与准入、半 Flit 打包、Request/Response 选择、发送 SRAM 队列和完整 Control 源组捕获。生产顶层 `tl_tx_prepared` 的 32 组双端配置通过，1,536 源组、5,248 分组和 6,912 字段完整到达；36 组单位配置、22 项接线故障与 8 项带负载复位故障检查通过。

生产发送组合的 WIDTH 8～16 × HEADER_DEPTH 1/2/3 共 27 配置，每组 35 项所有权/头部队列守恒断言完成无界归纳。该结论使用任意 SRAM 读值，不代表完整载荷形式证明。

[生产顶层工艺基线](docs/tl_tx_prepared_timing_review.md)已完成两位宽、五个标准单元角、三种 synthetic SRAM 视图和两周期共 60 组测量及证据审计。640 ps 主周期 0/30 收敛，6.4 ns 参考周期 26/30 收敛；WIDTH 8/16 最差 setup 为 −3.217651/−3.261416 ns，标准单元面积为 47,213.082/48,461.994 µm²，不含 SRAM 面积。生产顶层已完成[复位后二值工艺映射等价](docs/tl_tx_prepared_mapping_review.md)，包括完整输出/下一状态分区比较及独立复位、游标和空闲载荷关系证明。时序收敛、真实宏签核与最终双 IP 交付仍未完成。

详细范围见[工程状态](docs/status.md)。模块结果及复跑入口分别见[信用准入](docs/tl_credit_admission_review.md)、[半Flit打包](docs/tl_tx_packer_review.md)、[类别选择](docs/tl_tx_channels_review.md)、[发送SRAM](docs/tl_tx_buffered_review.md)、[字段分组](docs/tl_control_partition_review.md)和[工艺时序基线](docs/tl_control_partition_timing_review.md)。发送数据源必须按 `o_data_accepted` 的实际接纳数量推进，最小容量支持部分入队。

波形和终止任务的编译产物按工作区要求清理；保留的阶段日志、输入快照及校验清单位于本地忽略目录。早期已删除证据的历史数字仅作状态摘要。

## 外部输入

规范正文、PDK/Liberty、SRAM 模型、SerDes/VIP 和本地主机配置不随本仓库分发。`KD28_ROOT` 指向有权使用的外部仓库，其文件清单及校验值见 [依赖登记](third_party/kd28_dependency.json)。`specs/private/`、`third_party/private/` 与 `config/local.json` 被忽略。源码许可证尚未指定。
