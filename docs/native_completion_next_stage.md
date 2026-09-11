# 原生完成路径下一阶段验收

本阶段从源码 `4bd9d6643b69808dbc50ce0c397e67488062ab71` 继续；最近已核验的 Overflow 发布为 `779a2e8b72bfcbd644e246288914387c75eac9df`。候选结果只有安装、生产路径复跑和审查通过后才计入已实现清单。

| 工作包 | 必须交付的实际功能 | 验收重点 |
| --- | --- | --- |
| Endpoint response formatter | 保存 command 握手时的完整原请求身份和响应几何，将匹配 token 的 backend result 转为 native 响应候选 | 不使用已经指向下一请求的 issue 字段；Read 所有预期拍完整；反压保持；最终 native 消费与 context release 分开；不支持操作明确拒绝 |
| Switch prepared assembler | 从明确支持的布局恢复可交给 prepared 的字段组及其 Data/Auth 关联 | 不猜跨 ingress 所有权；不伪造 Auth；区分 Control capture、Data admission 和最终发送；拒绝不支持的布局 |
| RAS completion arbitration | 正常与 dummy 完成共享出口且保留身份、反压及独立销账事件 | 同沿隔离优先级、已展示但被反压的正常完成、部分正常响应后隔离、旧 epoch/复用身份、最后消费后销账 |

三个工作包先各自在隔离候选目录实现和验证，主线负责交叉接口审核、清单更新、生产路径回归及发布目录复跑。

## 必须保持的接口边界

现有 `endpoint_tag_table` 以完整 `(port, Tag)` 关联事务，不向外提供 RAS 账本的 slot/epoch；其完整 Read 应用结果宽度为 2048 位，而本地 dummy 完成输出为逐拍 512 位。连接二者之前必须有明确的身份映射、结果粒度转换和唯一释放所有者，不能直接把 ready 相连。

正常响应已被应用部分消费后再发生隔离时，重新从 Offset 0 生成全部 dummy 可能重复提交；另一方面，撤回已经展示的 valid 又可能破坏反压保持契约。仲裁候选必须明确整体所有权转移或可撤销边界，并用定向测试证明其策略；不能仅在最终完成通知处屏蔽 normal_retire。

当前仲裁候选采用整笔 2048-bit 结果和 256-bit mask，并显式提供 cancel。实际应用转移条件为 `valid && ready && !cancel`，同沿 cancel 优先；取消周期保持原身份和数据，沿后撤销候选。因此它是可撤销的本地事务接口，普通 ready/valid 消费者不能直接连接。dummy 前面的响应拍只进入本地组装存储，最后一拍的 ready 必须等到完整应用结果被真正接纳，随后才由原生成器产生 done。Tag 表的取消路径及身份映射仍待后续集成。

Switch 的本地完整记录保存和 TL 分类尚不能证明任意独立 ingress 混排后满足同一个出口序列上下文。字段重组的支持范围和拒绝条件必须先于实际 prepared/TL/DL 接线明确。

## 完成条件

每项须提供真实 RTL、独立模型或 scoreboard、自检 SV、故障注入、静态检查与可迁移复跑入口。测试范围及未实现边界写入执行文档。结构计数不是协议完成百分比；完整双 IP 仍须满足交付计划中的功能、CDC/RDC、工艺 STA 和外部平台边界。
