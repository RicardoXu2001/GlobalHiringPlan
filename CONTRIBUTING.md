# 开发与每周合并流程

当前采用 `develop → main` 的工作方式，适用于单人起步和后续成员接手。

## 分支职责

- `main`：保存通过当周验收的可试玩成果，作为展示和交接基线。
- `develop`：日常开发与集成，允许存在明确记录的未完成项。
- 成员加入后，从 `develop` 建立短期任务分支，完成后通过 PR 合并回 `develop`。认领入口与验收见 [任务清单](本周任务与接手清单.md)。

## 每周合并

1. 汇总本周实际完成的功能、修复与已知问题，更新 [CHANGELOG](CHANGELOG.md)。
2. 运行与改动相关的回归；玩法改动运行 `godot/验证.ps1`，并实际试玩核心循环、结局、重开和存档继续。文档改动检查内容与链接即可。
3. 核对源码和验证记录对应；明确未覆盖项与交付限制，更新 `qa/QA_REPORT.md` 和任务状态。
4. 创建 PR：目标为 `main`，来源为 `develop`。描述本周成果、验收结果与遗留问题。
5. 验收通过后合并；未通过则修复或将未完成内容留在 `develop`，不要只因到了周末就合并。合并后将 `main` 同步回 `develop`，继续下一周开发。

当前只有发起人一人，PR 用于集中检查成果与保留记录，暂不强制他人审批。扩队后再按实际人员设置审批要求。

## main 的远端保护设置

在 GitHub 仓库 Settings → Branches 为 `main` 添加保护规则：

- 启用 **Require a pull request before merging**。
- 当前不启用 **Require approvals**，避免单人无法完成审批。
- 启用 **Do not allow bypassing the above settings**，使保护同样适用于管理员。
- 不允许强制推送或删除分支。
- 不启用 **Lock branch**；它会令分支只读，妨碍每周合并。
- 当前尚无 CI，不填写不存在的必需状态检查；接入 CI 后再启用对应检查。

以上是拟采用的配置，不是已生效的证明。2026-10-13 已建立远端 `develop`；本次浏览器未登录管理账号，`main` 保护规则尚待配置与验证。

参考：[GitHub 分支保护说明](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches)。
