# MoonBridge 实施记录与剩余工作

核对日期：2026-10-27（Asia/Shanghai）。设计决策见 [`2026-10-26-moonbridge-design.md`](2026-10-26-moonbridge-design.md)，实际规则和验证证据分别见 [`../rules.md`](../rules.md) 与 [`../verification.md`](../verification.md)。

## 已完成的本地阶段

### 1. 规则与选题核验

- 已按 10 月官网、正式章程和 8 月补充页记录截止时间冲突、报名规则、材料、许可证、CI、Mooncakes 与工具链要求。
- 已区分硬性要求、建议、用户质量目标和待确认事项；没有把 8 月代码行数参考当作 10 月门槛。
- 已核对 MoonBit FFI 和 Mooncakes 项目元数据。MoonBridge 定位为窄范围的头文件生成和 native 库封装，不声称创造了 MoonBit 导出机制。

### 2. 工具链与项目骨架

- 2026-10-27 官方稳定升级完成并返回 `Moonbit installed successfully`；版本仍为 `moon 0.1.20261023` / `moonc v0.10.17+d971670cd`，同日 Windows 回归通过。
- 在独立 `moonbridge/` 目录创建 `wccerty/moonbridge` 模块；工具链、缓存与 registry 数据均在忽略目录中。
- 仓库当前分支为 `main`；已创建公开 GitHub 仓库 `https://github.com/wccerty/moonbridge` 并配置 `origin`、模块仓库 URL。当前身份查询返回 `wccerty`；远端仍无提交，仓库本地作者邮箱待用户提供。

### 3. MoonBit 功能、示例和文档

- 根模块实现 `#export_name` 声明扫描、标量 ABI 校验、确定性 C 头文件生成，以及参数错误和不支持类型诊断。
- 支持 `Bool`、`Int32`、`UInt32`、`Int64`、`UInt64`、`Float`、`Double` 参数/返回及 `Unit` 返回；不支持的托管类型被拒绝。
- 提供 Linux `.a/.so` 打包脚本和调用 MoonBit 数组的内部实现示例；C ABI 边界只暴露标量。9 个示例导出覆盖全部支持的类型映射。
- 提供 README、C/C++ 消费者、Apache-2.0 许可证、第三方来源/许可说明、提交用事实底稿和验收清单。

### 4. 本地验证

- Windows x86-64：MoonBit 格式、检查、测试、接口文件和 release 构建通过；MSVC C/C++ 消费者链接 `.lib` 并运行成功。
- Ubuntu 24.04 x86-64：格式、检查、4 项测试、接口文件、release 构建通过；Linux 打包器生成 `.a/.so`，GCC/G++ 消费者分别对两种库链接并运行成功，覆盖所有 ABI 映射；`.so` 无 `TEXTREL`。
- `.github/workflows/ci.yml` 已在本地解析，Linux 等价工作流在容器内运行通过。公开仓库已经存在；远程 Actions 待首次推送后验证。
- `moon.mod` 的 `repository` 字段已填写 GitHub 地址；更新后的 `moon package --list` 通过且无缺少仓库 URL 警告。

## 剩余阶段

### 5. 账号核验、真实里程碑提交和远程仓库

1. 当前有效 GitHub CLI 会话已核验为 `wccerty`；未读取 GitHub 令牌或历史账号。
2. 已按功能里程碑创建 13 个有意义提交，推送后 GitHub 将作者关联为 `wccerty`。
3. 公开 GitHub 仓库 `main` 已推送并成为默认分支；主 CI 与 Copilot setup 工作流都已成功。
4. Mooncakes dry-run 已通过包内检查，但服务报告当前 Mooncakes CLI 登录身份与 owner 不匹配；用户需登录 Mooncakes CLI 为 `wccerty` 后再完成发布。

### 6. 报名材料与赛事确认

1. 向主办方确认 10 月官网截止日期与章程旧日期冲突、具体截止时刻/时区和当前表单字段。
2. 参赛者本人依据 [`../../submission/facts-for-human-proposal.md`](../../submission/facts-for-human-proposal.md) 改写正式一页申报书。
3. 确认赛事群要求、按本期表单提交申报并保存回执。

## 验收来源

- 官方规则：[`../rules.md`](../rules.md)
- 选题边界：[`../selection.md`](../selection.md)
- 本地实际命令和结果：[`../verification.md`](../verification.md)
- 参赛前状态：[`../../submission/acceptance-checklist.md`](../../submission/acceptance-checklist.md)
