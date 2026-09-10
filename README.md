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

实际TL链路已接入接收SRAM退休到FC发布、整段信用准入、半Flit打包、独立Request/Response选择、发送SRAM队列，以及完整Control字段的容量分组。最新分组阶段32组双端配置完成6,912个字段、2,304个完整Single-Beat读回复；4,856个单位RTL向量通过，72次实际故障注入全部检出。

工艺测量已推进到Control分组模块：WIDTH8/16 × 五角 × 两周期共20组STA中6组通过，主周期和慢角参考周期存在setup违例；该模块不能宣称目标频率达标。完整UPLI转换、每VC调度、单笔超容量事务、其余TL消息、完整协议证明和集成顶层STA仍在推进。

详细范围见[工程状态](docs/status.md)。模块结果及复跑入口分别见[信用准入](docs/tl_credit_admission_review.md)、[半Flit打包](docs/tl_tx_packer_review.md)、[类别选择](docs/tl_tx_channels_review.md)、[发送SRAM](docs/tl_tx_buffered_review.md)、[字段分组](docs/tl_control_partition_review.md)和[工艺时序基线](docs/tl_control_partition_timing_review.md)。发送数据源必须按 `o_data_accepted` 的实际接纳数量推进，最小容量支持部分入队。

波形和终止任务的编译产物按工作区要求清理；保留的阶段日志、输入快照及校验清单位于本地忽略目录。早期已删除证据的历史数字仅作状态摘要。

## 外部输入

规范正文、PDK/Liberty、SRAM 模型、SerDes/VIP 和本地主机配置不随本仓库分发。`KD28_ROOT` 指向有权使用的外部仓库，其文件清单及校验值见 [依赖登记](third_party/kd28_dependency.json)。`specs/private/`、`third_party/private/` 与 `config/local.json` 被忽略。源码许可证尚未指定。
