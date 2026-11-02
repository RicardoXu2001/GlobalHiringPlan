# 开发与每周合并流程

当前共三人开发，采用 `任务分支 → develop → main` 的工作方式。主责、工时与近期安排见 [三人开发指南与计划](三人开发指南与计划.md)。

## 分支职责

- `main`：保存通过当周验收的可试玩成果，作为展示和交接基线。
- `develop`：日常开发与集成，允许存在明确记录的未完成项。
- 每人从最新 `develop` 建立短期任务分支，完成后通过 PR 合并回 `develop`，由至少一位其他成员复核。认领入口与验收见 [任务清单](本周任务与接手清单.md)。

## 每周合并

1. 汇总本周实际完成的功能、修复与已知问题，更新 [CHANGELOG](CHANGELOG.md)。
2. 运行与改动相关的回归；玩法改动运行 `godot/验证.ps1`，并实际试玩核心循环、结局、重开和存档继续。文档改动检查内容与链接即可。
3. 核对源码和验证记录对应；明确未覆盖项与交付限制，更新 `qa/QA_REPORT.md` 和任务状态。
4. 创建 PR：目标为 `main`，来源为 `develop`。描述本周成果、验收结果与遗留问题。
5. 验收通过后合并；未通过则修复或将未完成内容留在 `develop`，不要只因到了周末就合并。合并后将 `main` 同步回 `develop`，继续下一周开发。

每个 PR 由至少一位其他成员复核；账目、存档和胜负改动需交叉复算或实机复现。A 汇总周验收结果，B 确认技术与构建风险，C 汇总交互和试玩问题，再决定是否合入 main。

## main 的远端保护设置

在 GitHub 仓库 Settings → Branches 为 `main` 添加保护规则：

- 启用 **Require a pull request before merging**。
- 三人阶段建议启用 **Require approvals**，要求至少一位其他成员审批。
- 启用 **Do not allow bypassing the above settings**，使保护同样适用于管理员。
- 不允许强制推送或删除分支。
- 不启用 **Lock branch**；它会令分支只读，妨碍每周合并。
- 当前尚无 CI，不填写不存在的必需状态检查；接入 CI 后再启用对应检查。

以上是拟采用的配置，不是已生效的证明。2026-10-13 已建立远端 `develop`，当时浏览器未登录管理账号；截至本次文档更新（2026-10-16），未取得 `main` 保护已生效的确认，由 A 后续核对。

参考：[GitHub 分支保护说明](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches)。
