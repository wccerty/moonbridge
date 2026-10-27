# MoonBridge 申报事实底稿（供参赛者本人改写）

> 这不是可直接提交的一页申报书。正式章程要求申报书由参赛者本人撰写；此页只整理可核验事实、边界和证据，提交前请用自己的表达重写。

## 项目定位

- 项目名：MoonBridge。
- 方向：开发者工具 / MoonBit 与 C/C++ 集成。
- 解决的问题：把 MoonBit 包里的 `#export_name` 标量导出声明转换成 C/C++ 头文件，并在 Linux 上构建外部项目可调用的 `.a` 和 `.so`。
- 新增部分：可审阅的确定性头文件、ABI 类型白名单与错误诊断、Linux PIC 共享库打包、独立 C/C++ 消费者验证。
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
- MoonBit 代码：7 个 `.mbt` 文件，共 756 行物理行（含注释、空行和测试；不是赛事门槛）。

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

- GitHub 公开仓库：[`wccerty/moonbridge`](https://github.com/wccerty/moonbridge)，已创建；`origin` 与 `moon.mod` 仓库 URL 已配置，但尚无推送提交。
- 当前 GitHub CLI 登录名：2026-10-27 仅查询 `gh api user --jq .login`，结果为 `wccerty`；未读取凭据或历史账号。
- 提交作者邮箱：未配置，等待账号持有人提供已验证邮箱或 noreply 地址。
- 远程默认分支、Issues/PR/提交历史与 GitHub Actions 结果：待首次推送后核实。
- Mooncakes 发布：未发布。
- 十月赛报名表当前字段、截止具体时刻/时区、正式章程中 9 月 30 日旧日期冲突：待向主办方确认。
- 正式一页申报材料：请参赛者阅读本底稿后亲自改写并确认。
