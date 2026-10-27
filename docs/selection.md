# MoonBridge 选题评估

核对日期：2026-10-26。评估范围为通用 C/C++ 集成；本次只检查 Mooncakes 元数据和 MoonBit 官方文档，没有读取相关 GitHub 仓库内容。

## 结论

选题值得继续，但原始一句话把编译器能力说得过于直接。MoonBit 已有 `#export_name`、`foreign_library` 和基础 C ABI 类型映射；MoonBridge 的真实新增价值是从导出声明生成可审阅的 C 头文件，并生成外部 C/C++ 工程可用的静态/共享库。已在 Windows 上用 C/C++ 消费者调用 `.lib`，并在 Linux 上生成 `.a`、重编 PIC runtime/package C 对象生成无文本重定位的 `.so`，四种消费者链路均通过并运行成功。

这一区域有实际价值：C/C++ 工程无需改用 MoonBit FFI 绑定生成工具，就可以调用 MoonBit 模块。示例现有 9 个导出，分别实测 `Bool`、有符号/无符号 32/64 位整数、`Float`、`Double`、`Unit` 返回和内部使用 MoonBit 数组的实现；C 与 C++ 消费者在 Windows `.lib` 和 Linux `.a/.so` 上均运行成功。

## 生态重合检查

| 项目 | Mooncakes 元数据摘要 | 与 MoonBridge 的关系 |
|---|---|---|
| `shop1111/moonbindgen` | 通过 Clang 从 C 头文件生成 MoonBit native C FFI 声明；MIT；查询时最新 0.6.0。 | C → MoonBit，方向相反。 |
| `icyaaaww/moonbind` | 从 C 头文件生成类型安全 MoonBit FFI 绑定；Apache-2.0；查询时最新 0.10.0。 | C → MoonBit，方向相反。 |
| `shop1111/moonohos` | HarmonyOS 原生模块框架；Mooncakes 描述称其生成 ArkTS/TypeScript 绑定和 C 桥接代码；Apache-2.0；查询时最新 0.4.0，发布于 2026-10-21。 | 具有导出桥接的交叉，但描述明确为 HarmonyOS/HAR 平台框架，不等于通用 Linux `.a/.so` 工具。需在远程仓库核验准确边界后再申报。 |

MoonBit FFI 文档中的 `#export_name` 限定新函数名，C 后端文档给出简单标量 ABI 映射。MoonBridge 不应宣称“生态没有 MoonBit 导出 C 的机制”，而应明确问题是缺少通用的头文件生成、生命周期约束和可链接库打包流程。

## 技术边界

- **当前头文件生成器支持的类型**：`Bool`、`Int32`、`UInt32`、`Int64`、`UInt64`、`Float`、`Double`，以及 `Unit` 返回值。无载荷 enum 暂未实现。
- **首版拒绝的类型**：`String`、`Bytes`、数组、结构体/载荷 enum、闭包、泛型、可选参数、错误返回和其他布局不稳定类型。拒绝原因要包含文件与行号。
- **已证明平台**：Windows x86-64，release `foreign_library` 构建产出 `.lib`，MSVC C 与 C++ 消费者分别编译、链接并运行成功。
- **已证明平台**：Linux x86-64，release 构建产出 `.a`；打包脚本将 MoonBit 生成的 C 源与匹配 toolchain 的 runtime C 源重新编译为 PIC，生成无 `TEXTREL` 的 `.so`。C/C++ 消费者分别链接静态和共享产物，均运行成功。
- **核心风险**：官方包配置文档仍称 native 后端不直接导出 `.so`/`.dll`。MoonBridge 只在已测试的 Linux x86-64 GCC 兼容环境用 PIC 重编译与链接解决 `.so`，不把这条流程泛化到其他操作系统、架构或链接器。

## 参赛适配度

定位为“开发者工具”符合官网方向；边界清楚，已用独立 Windows C/C++ 和 Linux C/C++ 消费者覆盖头文件、静态库和共享库调用。本地已配置 Ubuntu CI 来重复这些证据；远程结果待仓库可用后确认，并保留对其他 Linux 工具链的限制说明。

## 来源

- [MoonBit FFI 文档](https://docs.moonbitlang.com/en/latest/language/ffi.html)
- [MoonBit 包配置与 native 后端限制](https://docs.moonbitlang.com/en/latest/toolchain/moon/package.html)
- [Mooncakes](https://mooncakes.io/)：通过 `moon search`、`moon view` 查看上述包名、摘要、版本、许可与发布时间。
- 竞赛规则见 [docs/rules.md](rules.md)。
