# TODO

## 当前状态
- 项目已拆成 LÖVE 入口、场景、实体、组件、关卡/边界、升级和测试几块；`main.lua` 主要负责启动、全局资源和场景注册。
- 自动化测试已可通过独立 Lua 运行：`lua tests/run.lua` 和 `luajit tests/run.lua` 当前均通过 44 个测试。
- 当前分支 `main` 已基于 `origin/main` rebase，处于 `ahead 1` 状态；本轮文档更新尚未提交，未跟踪的 `.agent/`、`.codex` 是本地工具文件。
- 最近一次冲突解决后，`EdgeEnemySpawners` 独立组件文件已被远端删除，刷怪器重建逻辑保留在 `src/edge.lua`。

## 当前待办
- [ ] 将 `tests/bullet_collision_spec.lua` 注册到 `tests/run.lua`，避免新碰撞用例被默认测试入口遗漏。
- [ ] 运行一次 `timeout 5s love .` 冒烟启动，确认 rebase 后主流程仍能进入游戏。
- [ ] 人工验证右侧/左侧刷怪边：敌人应向场地内侧偏移，并且同波敌人不应明显堆叠。
- [ ] 人工验证升级界面英文文案、升级选择、波次结束暂停/恢复流程。
- [ ] 若需要共享给远端，推送当前领先的 1 个提交。

## 已完成
- [x] 建立 `tests/` 测试骨架：`test_bootstrap.lua`、`helpers/testlib.lua`、`run.lua`。
- [x] 新增并扩展测试覆盖：组件框架、实体组件生命周期、世界查询/移除、几何、关卡边规则、关卡、敌人、边界、升级定义、升级 UI、波次管理和玩法效果。
- [x] 安装并验证 `lua` 与 `luajit`，当前两套运行时都能执行测试入口。
- [x] 将 `Level:randomizeEdges()` 规则拆到 `src/level_edge_rules.lua`，降低 `Level` 分支复杂度。
- [x] 新增 `src/geometry.lua`，抽取线段、矩形、传送门和边法线相关几何逻辑。
- [x] 将 `src/utils.lua` 中的几何辅助接入共享几何逻辑，并收束 `src/edge.lua` 的传送门出口计算。
- [x] 为 `Entity` 增加组件容器、tag、world 引用与统一生命周期分发。
- [x] 为 `World` 增加事件总线、延迟添加队列与按 tag 查询能力。
- [x] 将玩家移动、生命值、碰撞动作、冷却、朝向、追踪、移动、无敌、浮动和出界清理等可复用行为拆入 `src/components/`。
- [x] 将玩家受伤、敌人接触伤害、子弹命中、心形拾取迁移为组件驱动。
- [x] 新增升级系统数据：子弹尺寸、边界穿梭、移动速度、射速、边界强化和恢复生命。
- [x] 将升级界面标题、描述、等级文案数据化，并切换为英文文案。
- [x] 引入 `WaveManager` 管理波次、升级节奏、同屏敌人上限和分批刷怪。
- [x] 新增护盾敌人波次递进逻辑，并在 rebase 冲突解决中保留敌人类型分配。
- [x] 改进边界刷怪位置：刷怪器记录父边，敌人向场地内侧偏移，并避开已占用生成点。
- [x] 将 `src/scenes/` 拆出 gameplay、menu、pause、gameover 场景，降低 `main.lua` 职责。
- [x] 修正 `src/enemy.lua` 对 `src/Item.lua` 的大小写引用问题。

## 风险/注意事项
- `tests/bullet_collision_spec.lua` 已存在但尚未纳入统一入口，当前 44 个通过测试不包含它。
- `src/Item.lua` 仍是大写文件名；新增模块应继续使用小写 snake_case，已有引用必须保持大小写正确。
- `src/edge.lua` 重新承担刷怪边逻辑；如果后续再次组件化边行为，需要先确认不要恢复已删除的 `src/components/edge_enemy_spawners.lua`。
- 当前自动化测试主要覆盖逻辑与组件行为，渲染、音频、手感和完整 LÖVE 场景流程仍需要人工验证。

## 验证记录
- `lua tests/run.lua`：通过，`tests passed: 44`。
- `luajit tests/run.lua`：通过，`tests passed: 44`。
- `git status --short --branch`：`main...origin/main [ahead 1]`，当前有 `AGENTS.md`、`TODO.md` 文档更新，另有 `.agent/`、`.codex` 未跟踪。
