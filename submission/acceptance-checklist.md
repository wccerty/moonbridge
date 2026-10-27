# 参赛前验收清单

更新日期：2026-10-27。状态只反映当前实际证据。

## 本地项目

- [x] 独立 MoonBit 模块目录与 Git 仓库已创建，初始分支为 `main`。
- [x] 根目录 Apache-2.0 许可证及第三方来源说明。
- [x] README、使用边界、C/C++ 示例和来源信息。
- [x] MoonBit 测试：`moon test --deny-warn`，4/4 通过。
- [x] 格式、静态检查：`moon fmt --check`、`moon check --deny-warn` 通过。
- [x] MoonBit 接口检查：`moon info` 已运行，第一方 `.mbti` 为编译器生成且无手工差异。
- [x] Windows release `.lib`：MSVC C 和 C++ 消费者编译、链接、运行通过。
- [x] Linux release `.a/.so`：Ubuntu 24.04 下 C 和 C++ 消费者分别链接两种库并运行通过；`nm` 有导出符号，`readelf` 未发现 `TEXTREL`。
- [x] CI 工作流已写入 `.github/workflows/ci.yml`；YAML 可解析，Linux 等价步骤在本地 Docker 中通过。
- [x] `moon package --list` 在 `moon.mod` 填入 GitHub URL 后复核；最终清单正常且不再提示缺少仓库 URL。
- [x] 当前 MoonBit 源规模：7 个 `.mbt` 文件、756 物理行；赛事材料未把 8 月规模参考误作本期门槛。

## 远程交付

- [x] 仅执行 `gh api user --jq .login` 核验当前 GitHub CLI 用户名；2026-10-27 在当前有效会话的命令输出为 `wccerty`、退出码 0。未读取令牌、历史账号或其他用户资料。
- [ ] 为真实 GitHub 账号配置可关联的提交作者邮箱；当前仓库未设置 `user.name` / `user.email`，因此尚无提交。
- [ ] 按真实开发里程碑提交至少 11 次有意义改动；不空提交、不回填日期、不伪造贡献者。
- [x] 已创建 GitHub 公共仓库 `https://github.com/wccerty/moonbridge`，并填写 `moon.mod` 的 `repository` 字段。
- [ ] 配置真实作者信息后推送 `main`；当前远程仓库尚无提交。
- [ ] 确认仓库 README、LICENSE、历史提交与 CI 结果可公开审阅。
- [ ] 首次推送后运行并记录实际远程 GitHub Actions 结果。
- [x] 检查 `moon package --list` 的最终清单；Mooncakes 发布仍待完成。

## 赛事申报

- [ ] 向主办方确认官网 10 月 31 日与章程 9 月 30 日冲突、截止时刻/时区及本期表单字段。
- [ ] 参赛者本人改写一页 Markdown 项目申报书；可参考 [`facts-for-human-proposal.md`](facts-for-human-proposal.md)，不得把事实底稿当成已署名的本人陈述。
- [ ] 报名表实际提交并留存回执；当前未提交。
- [ ] 按赛事规则加入交流群，将昵称改为实际 GitHub ID；当前未执行。
