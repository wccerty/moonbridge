# MoonBridge 申报事实底稿（供参赛者本人改写）

> 这不是可直接提交的一页申报书。正式章程要求申报书由参赛者本人撰写；此页只整理可核验事实、边界和证据，提交前请用自己的表达重写。

## 项目定位

- 项目名：MoonBridge。
- 方向：开发者工具 / MoonBit 与 C/C++ 集成。
- 解决的问题：把 MoonBit 包里的 `#export_name` 标量导出声明转换成 C/C++ 头文件，并在 Linux 上构建外部项目可调用的 `.a` 和 `.so`。
- 新增部分：可审阅的确定性头文件、ABI 类型白名单与结构化诊断、版本化 JSON manifest、ABI 人类可读报告、递归包扫描、生成头文件漂移检查、版本间 ABI 兼容性比较、Linux PIC 共享库打包、独立 C/C++ 消费者验证。
- 不是从零发明 MoonBit 函数导出机制。MoonBit 已提供 `#export_name` 和 `foreign_library`；MoonBridge 提供通用生成与打包流程。

## 至少三个完整使用场景

1. **C++ 命令行工具复用 MoonBit 计算模块**：在 MoonBit 包标记简单 `Int32` 函数并声明 `#export_name`，运行 MoonBridge 得到 `.h/.a`，C++ 程序包含生成头文件并静态链接；示例中 `moonbridge_add_i32(20, 22)` 返回 42。
2. **Linux C 服务加载 MoonBit 业务函数**：使用 `scripts/package-linux.sh` 从 MoonBit `foreign_library` 包生成 `.h/.so`，C 服务链接共享库并调用导出函数；打包过程确保生成物没有 `TEXTREL`，并核对头文件中的每个函数符号都出现在 `.so` 动态符号表。
3. **遗留 C 项目引入逐步迁移的 MoonBit 模块**：先将纯标量计算、校验或格式判定逻辑写成 MoonBit 函数，再生成头文件和本机库；调用方保留现有 C API 结构，CI 同时编译 C 与 C++ 消费者，便于逐步迁移与回归验收。

这些场景围绕同一项稳定能力，不代表字符串、集合、对象或异步接口已被支持。

## 核心功能与证据

- 逐个读取包内生产 `.mbt` 文件，识别 `#export_name` 与紧邻的 `pub fn` 标量签名；明确支持 `Bool`、定宽整数、`Float`/`Double` 及 `Unit` 返回值。
- 拒绝字符串、字节、数组参数、结构体、闭包、泛型、可选/命名/默认参数、错误返回和非法/重复 C 符号；错误含文件和行号。
- 输出包含 `<stdint.h>`、include guard、C++ `extern "C"` 的 `.h`；相同源码稳定生成相同内容。
- Linux 打包脚本保留 MoonBit 编译器生成的 `.a`；为 `.so` 将匹配工具链 runtime C 源和生成 C 源重编为 PIC，检查导出符号并拒绝文本重定位。
- 示例含 9 个导出，C/C++ 消费者实际调用全部支持映射：`Bool`、有符号/无符号 32/64 位整数、`Float`、`Double`、`Unit` 返回，以及内部申请 MoonBit 数组的 `Int32` 实现。Windows `.lib` 和 Linux `.a/.so` 链接运行均通过。
- 本地工具链：Moon `0.1.20261023`，`moonc v0.10.17+d971670cd`；Linux 验证使用 Ubuntu 24.04、GCC/G++ 13.3.0。
- MoonBit 代码：15 个 `.mbt` 文件、2,587 行物理行；去除空行与注释后为 2,320 行（实现 1,592 行、测试 728 行）。该统计不含赛事门槛判断；统计口径为仓库内 `.mbt` 文件。

## 创新性与生态边界

- `shop1111/moonbindgen` 和 `icyaaaww/moonbind` 从 C 头文件生成 MoonBit FFI 声明，方向为 C → MoonBit。
- `shop1111/moonohos` 服务 HarmonyOS 原生模块并生成相应宿主绑定/C 桥接；需在最终申报中明确其与通用 Linux C 库工具的交叉，不宣称完全没有相关方案。
- MoonBit 官方 native 包文档仍说明不直接导出 `.so/.dll`。MoonBridge 的 Linux `.so` 路径依赖本地工具链附带的 runtime C 源和 GCC 兼容编译器，已在当前版本/Ubuntu 24.04 实测；不能外推到 Windows DLL、其他 CPU 或任意编译器。
- 头文件扫描器实现的是窄语法，不是完整 MoonBit 解析器。每个接入包应按支持的声明格式编写，并由 `moon build` 作最终语言语法验证。

## 来源、依赖与许可

- 项目许可证：OSI 认可的 Apache-2.0，根目录 `LICENSE`。
- MoonBit CLI 文件操作依赖 `moonbitlang/async@0.22.5`（Apache-2.0）。
- Linux 二进制库包含 MoonBit 编译器生成代码和 runtime 对象；打包脚本从已安装官方工具链读取 Apache-2.0 runtime C 源并编译，不将该源码复制进仓库。分发 `.a/.so` 时保留 `THIRD_PARTY_NOTICES.md` 与上游许可证。
- 未复制 `moonbindgen`、`moonbind`、MoonOHOS 的实现、测试数据或二进制。
- 规则矩阵、原始资料链接与待确认项见 [`docs/rules.md`](../docs/rules.md)；构建日志见 [`docs/verification.md`](../docs/verification.md)。

## 提交前状态

- GitHub 公开仓库：[`wccerty/moonbridge`](https://github.com/wccerty/moonbridge)，此前核验的 `main` 为默认分支；截至 2026-10-27，GitHub 将已推送的 13 个提交均关联到 `wccerty`。2026-10-28 新增 ABI 功能提交尚未推送。
- 本次远端核验：`gh api user --jq .login` 返回 HTTP 401，因此没有推送或触发远端 CI；未读取令牌、历史账号或其他用户资料。
- 当前 GitHub CLI 登录名：2026-10-27 仅查询 `gh api user --jq .login`，结果为 `wccerty`；未读取凭据或历史账号。
- 提交作者：按用户授权使用 `wccerty` 和 GitHub ID-based noreply 格式，仅配置在本仓库；远端已验证作者关联。
- GitHub Actions：既有主 CI 与 Copilot setup 均成功运行，见 [`docs/verification.md`](../docs/verification.md)；本次本地 ABI 扩展尚未推送，因此未声称其已通过远端 CI。
- Mooncakes 发布：未发布；dry-run 包内检查通过，但 CLI 登录身份与 module owner 不匹配，需账号持有人登录为 `wccerty` 后重试。
- 十月赛报名表当前字段、截止具体时刻/时区、正式章程中 9 月 30 日旧日期冲突：待向主办方确认。
- 正式一页申报材料：请参赛者阅读本底稿后亲自改写并确认。
