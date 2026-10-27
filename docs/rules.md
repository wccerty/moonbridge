# 2026 年 10 月 MoonBit 黑客松规则核对

核对日期：2026-10-27（Asia/Shanghai）。本文只记录本期官方页面和现场工具输出，不从往届活动推断。

## 来源与更新时间

| 来源 | 页面标示的更新时间 | 核对结果 |
|---|---|---|
| [2026 MoonBit 黑客松官网](https://moonbitlang.github.io/Hackathon2026/) | 页面未显示更新时间；2026-10-27 再次通过官方站点搜索结果复核 | 搜索结果仍显示当前赛季为“十月赛”、报名与验收截止为 10 月 31 日；未能通过本次页面抓取核实截止时分/时区。 |
| [MoonBit 黑客松大赛章程](https://bxup9uklfcb.feishu.cn/wiki/Dx4Bwd6D1i3GfHkajQCcF7SznEd) | 上次可读取页面显示“10 月 10 日修改”（2026-10-26）；2026-10-27 刷新读取失败 | 上次读取的流程段仍写 9 月 30 日，与官网十月赛日期冲突；本次未能重新读取，冲突待主办方确认。 |
| [2026 国产基础软件生态开源大赛—8 月黑客松活动说明](https://bxup9uklfcb.feishu.cn/wiki/KNrVwEVFziPHiGkQtwhc6w3gndd) | 上次可读取页面显示“7 月 28 日修改”（2026-10-26）；2026-10-27 刷新读取失败 | 上次读取显示该页专属 8 月活动；本次未能重新读取，仍不将其 8 月 24 日截止日期或规模参考套用到 10 月赛。 |

## 官方硬性要求

| 项目 | 要求及证据 | 状态 |
|---|---|---|
| 截止时间 | 官网本期赛程写 2026-10-31 报名与验收截止；官网未注明当天具体时刻或时区。章程仍写 9 月 30 日。 | 按官网 10 月 31 日排期；截止时刻与时区待确认，章程矛盾项待主办方确认。 |
| 报名与修改 | 官网写十月最多提交 3 次，以通过审核前最后一次有效提交或修改时间为准；未通过的项目可以修改，滚动审核。 | 硬性要求。 |
| 申报内容 | 章程要求一页 Markdown 项目申报书，说明项目名称、简介、方向与通用性、至少 3 个完整使用场景、核心功能、原创/移植/参考来源；移植需写来源链接与许可证。章程另要求仓库链接且有不少于 10 个有效 commits。 | 硬性要求；因章程时间段落过期，具体表单字段以当前十月报名表为准。 |
| 项目原创性 | 新项目不得与 Mooncakes 上维护良好且功能高度重合的成熟项目重复；已有项目可参赛，但必须有本期实质新增工作。 | 硬性要求。 |
| 仓库 | 官网要求公开仓库、持续提交并保留 commits、Issues、PR 与更新记录；章程明确要求上传到 GitHub。 | GitHub 公开仓库为硬性要求。 |
| 语言与可运行性 | 项目以 MoonBit 为主要实现语言；源码需完成所申报功能；提供 README、可复现示例和覆盖核心路径的测试。 | 硬性要求。 |
| 持续集成 | 章程验收要求配置 CI，并覆盖检查、构建和测试流程。 | 硬性要求。 |
| 发布 | 章程要求项目发布到 mooncakes.io。 | 硬性要求。 |
| 开源许可 | 章程要求 OSI 认可的开源许可证；移植或参考项目必须遵循上游许可并保留来源说明。 | 硬性要求。 |
| 团队与赛事群 | 官网要求每队不超过 3 人；参赛选手需加入赛事交流群并将群昵称改为自己的 GitHub ID，否则会影响奖金发放。 | 硬性要求。 |
| AI 辅助 | 官网验收标准要求 AI 辅助过程可解释，参赛者掌握目标、路径和质量；8 月补充页也要求参赛者对代码、来源、许可和可维护性负责。 | 当前官网中的“AI 可解释”为硬性验收标准；8 月页的细则只作背景参考。 |

## 官方建议

- 官网建议选边界清晰、一个月内可交付并验证的项目；给出的方向包含工具库、数据处理、AI 应用和开发者工具。MoonBridge 属于开发者工具。
- 官网建议通过 Mooncakes 检查生态重合；章程建议申报前评估已有项目，并说明建设类似项目的明确理由。
- 8 月活动说明曾把 4,000–10,000 行有效 MoonBit 代码列为“参考规模”，同时明确代码行数不是验收标准。该页面属于 8 月活动，**不作为本期硬性门槛**；本项目以功能闭环和可复现验收为目标，不为行数扩张范围。
- 章程鼓励公开、连续、可追踪地保留提交、Issue、PR、测试和更新记录。

## 本项目质量目标（用户要求）

- 使用可核实的最新稳定 MoonBit 工具链；记录本机、CI 的完整版本输出。
- 至少 11 次有实质内容的提交，按真实研发里程碑提交；不空提交、不拆分凑数、不回填日期。
- MoonBit 承担主要实现；提供完整根目录 Apache-2.0 许可证、真实 C 集成示例、必要测试和来源/许可清单。
- 按目标平台运行 `moon fmt --check`、`moon check --deny-warn`、`moon test --deny-warn`、`moon info`、构建与示例；不对 `moon fmt` 或 `moon info` 猜加 `--deny-warn`。
- 检查 Mooncakes 发布包清单、`pkg.generated.mbti` 差异和 CI 远程运行结果。
- Git 提交作者必须是实际 GitHub 账号持有人 wccerty；只在本地工作与验证完成后核验当前有效 GitHub 登录身份。

## MoonBridge 选题核验

截至 2026-10-26，通过 Mooncakes CLI 搜索得到：

- [`shop1111/moonbindgen`](https://mooncakes.io/docs/shop1111/moonbindgen)：从 C 头文件生成 MoonBit native C FFI 声明，方向为 C → MoonBit。
- [`icyaaaww/moonbind`](https://mooncakes.io/docs/icyaaaww/moonbind)：同样从 C 头文件生成 MoonBit FFI 绑定，方向为 C → MoonBit。
- [`shop1111/moonohos`](https://mooncakes.io/docs/shop1111/moonohos)：2026-10-21 发布的 HarmonyOS 专用 MoonBit 原生模块框架；Mooncakes 摘要称其从配置生成 ArkTS/TypeScript 绑定和 C 桥接代码。它与通用 C ABI 打包工具存在交叉，需在申报中明确限定通用 Linux/C 库场景。

MoonBit 官方 FFI 文档已描述 `foreign_library`、`#export_name` 和 C 后端标量 ABI 映射；所以不应声称 MoonBit 完全不能导出 C 符号。官方文档同时指出 native 后端目前不支持把 `foreign_library` 直接输出为可链接库（如 `.so`/`.dll`）。因此本选题的真实缺口是通用头文件生成与可复现的本机静态/共享库封装，不是从零发明函数导出属性。

来源：

- [MoonBit FFI 文档（nightly）](https://docs.moonbitlang.com/en/latest/language/ffi.html)
- [MoonBit 包配置与 native 后端限制](https://docs.moonbitlang.com/en/latest/toolchain/moon/package.html)
- [MoonBit 官方 2026-09-21 v0.10.14 发布说明](https://www.moonbitlang.com/updates/2026/09/21/index)
- [Mooncakes 搜索与模块元数据](https://mooncakes.io/)

## 待确认事项

1. 官网官方搜索结果于 2026-10-27 仍写 10 月 31 日；没有核实截止时分和时区。正式章程上次于 10 月 26 日读取，流程仍有 9 月 30 日旧日期；10 月 27 日刷新读取失败。
2. 10 月报名表的当前字段、文件/链接提交方式和审查结果通知时限尚未核实。
3. 赛事页面没有指定 MoonBit 工具链版本。MoonBit stable 文档将 `--dev` 定义为安装最新开发版本；不带 `--dev` 的官方 `moon upgrade` 使用稳定通道。2026-10-27 官方升级器成功完成（未使用 `--dev`），并报告已是最新，`moon version --all` 为 `moon 0.1.20261023` / `moonc v0.10.17+d971670cd` / `moonrun 0.1.20261023`。项目在该稳定版本上重跑本机格式、静态检查、测试和 release 构建均通过；具体命令与已知非致命依赖告警见 [`verification.md`](verification.md)。官方 2026-09-21 发布页列有较早的 `moonc v0.10.14`，不将该发布说明当作当前稳定版本清单。证据：[稳定版 `moon upgrade` 命令文档](https://docs.moonbitlang.com/en/stable/toolchain/moon/commands.html)、[官方升级服务](https://cli.moonbitlang.com)。
