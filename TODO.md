# TODO

## 本次目标
- 添加可扩展的测试基础设施
- 对当前代码做最小且安全的重构，便于后续开发新功能
- 在实施过程中持续同步改动与验证结果

## 待办
- [x] 建立测试目录与测试引导代码
- [x] 提取可测试的纯逻辑辅助模块
- [x] 重构 `Level` 中重复的边同步逻辑
- [x] 补充第一批核心逻辑测试
- [x] 检查并修复明显的跨平台大小写问题
- [x] 记录验证结果与后续建议

## 进行中
- [ ] 无

## 已完成
- [x] 为升级卡片加入更清晰的标题/描述/等级分区文案展示
- [x] 将玩家子弹默认行为改为碰到边界即销毁
- [x] 新增 `边界穿梭` 升级，并让玩家子弹穿越绿色边界改由升级解锁
- [x] 将 `Edge` 的绘制、传送、阻挡和刷怪器行为拆成独立组件
- [x] 将 `Level` 对边刷怪器的直接操作收口为 `Edge` 的组件接口
- [x] 新增 `Damageable` / `HitTargets` / `PickupOnTouch` 组件，继续把碰撞与生命值逻辑从实体中剥离
- [x] 将玩家受伤、敌人接触伤害、子弹命中、心形拾取迁移为组件驱动
- [x] 为 `Entity` 增加组件容器、tag、world 引用与统一生命周期分发
- [x] 为 `World` 增加统一事件总线、延迟添加队列与按 tag 查询能力
- [x] 将 `Player` / `Enemy` / `Bullet` / `EnemySpawner` / `Item` 的可复用行为拆到 components
- [x] 将主要实体通信从全局直接访问收口到 `World` 查询、事件与 `Entity:spawn` / `Entity:emit`
- [x] 修正 `PowerupScreenUI` 传入玩家引用错误，并消除玩家开火逻辑对场景层的耦合
- [x] 检查项目结构、核心模块与当前测试环境
- [x] 产出实施计划并获得确认
- [x] 创建 `TODO.md` 并初始化实施骨架
- [x] 新增 `src/geometry.lua`，抽取线段/矩形/传送门几何逻辑
- [x] 将 `src/utils.lua` 中的 `lerp_vec2` / `point_within` 接入共享几何逻辑
- [x] 用共享几何逻辑收束 `src/edge.lua` 中的重复计算与传送门出口计算
- [x] 为 `src/level.lua` 新增 `getCorners` / `setEdgesFromCorners` / `syncEdgeGeometry`
- [x] 为 `Level:new` 补齐 `rotation` / `isRotating` / `rotationSpeed` 的基础初始化
- [x] 修复 `src/world.lua` 中移除无效实体时可能重复 `free` 的问题
- [x] 修复 `src/enemy.lua` 对 `src/Item.lua` 的大小写引用问题
- [x] 新建 `tests/` 测试骨架：`test_bootstrap.lua`、`helpers/testlib.lua`、`run.lua`
- [x] 新增 `tests/geometry_spec.lua`，覆盖纯几何辅助逻辑
- [x] 新增 `tests/world_spec.lua`，覆盖世界实体添加/移除/更新的基础行为
- [x] 为 `tests/test_bootstrap.lua` 补齐 `Mathx = Batteries.mathx`，使测试环境与游戏运行时保持一致
- [x] 通过 LÖVE 临时启动器实际执行测试，结果为 `tests passed: 9`

## 风险/阻塞
- 组件化重构已尽量保持玩法不变，但 `Edge` 传送门逻辑顺手去掉了一次重复传送，实际手感仍建议再人工确认
- 当前环境可执行 `love`，但仍未检测到独立 `lua` / `luajit`；因此当前更适合通过 LÖVE 启动器执行测试
- 本次重构刻意控制范围，未触碰场景切换、渲染细节和具体玩法数值

## 验证记录
- 已新增 `tests/power_up_ui_spec.lua`，覆盖升级按钮标题/描述/等级文案装配
- 已通过 LÖVE 临时启动器再次执行测试，结果为 `tests passed: 26`
- 已再次执行 `timeout 5s love .` 冒烟启动，未出现即时启动报错（进程因超时退出码 `124` 结束，属预期）
- 已补充边界穿梭相关测试，并将升级/波次测试纳入统一入口
- 已通过 LÖVE 临时启动器再次执行测试，结果为 `tests passed: 23`
- 已再次执行 `timeout 5s love .` 冒烟启动，未出现即时启动报错（进程因超时退出码 `124` 结束，属预期）
- 已新增 `tests/edge_component_spec.lua`，覆盖边装配、传送和刷怪器重建行为
- 已通过 LÖVE 临时启动器再次执行测试，结果为 `tests passed: 19`
- 已再次执行 `timeout 5s love .` 冒烟启动，未出现即时启动报错（进程因超时退出码 `124` 结束，属预期）
- 已继续扩展组件化测试，覆盖生命值、命中和拾取行为
- 已通过 LÖVE 临时启动器再次执行测试，结果为 `tests passed: 16`
- 已再次执行 `timeout 5s love .` 冒烟启动，未出现即时启动报错（进程因超时退出码 `124` 结束，属预期）
- 已补充架构测试：`tests/entity_component_spec.lua`
- 已通过 LÖVE 临时启动器执行测试，结果为 `tests passed: 12`
- 已执行一次 `timeout 5s love .` 冒烟启动，未出现即时启动报错（进程因超时退出码 `124` 结束，属预期）
- 已人工检查以下文件的改动结构与关键逻辑：
  - `src/geometry.lua`
  - `src/utils.lua`
  - `src/edge.lua`
  - `src/level.lua`
  - `src/world.lua`
  - `src/enemy.lua`
  - `tests/geometry_spec.lua`
  - `tests/world_spec.lua`
- 已确认代码引用关系中不再存在 `src.item` 的大小写问题
- 已确认 `project_ratio_on_segment` 的旧实现已被共享模块替代，调用点已收口
- 已确认当前仓库内已存在可继续扩展的测试入口：`tests/run.lua`
- 首次通过 LÖVE 执行测试时失败：`src/geometry.lua` 依赖全局 `Mathx`，测试引导未镜像该全局
- 已补齐 `Mathx` 全局映射后重新执行，测试通过：`tests passed: 9`

## 后续建议
- 若要继续完善升级手感，可给 `边界穿梭` 增加更明显的视觉或音效反馈
- 下一步可继续把 `Level:randomizeEdges()` 的规则本身抽成独立规则模块，进一步减少 `Level` 分支
- 下一步可继续把 `Level:randomizeEdges()` 的规则本身抽成独立规则模块，进一步减少 `Level` 分支
- 若继续做架构收口，可把 gameplay 状态更新流程拆成 system/controller，减少 `main.lua` 职责
- 下一步可继续把 `Edge` 的行为拆成边组件或规则对象，减少 `edgeType` 分支
- 若要进一步收紧架构，可给 `main.lua` 增加 gameplay controller，把场景内流程也从入口文件下沉
- 下一步可把更多碰撞效果也下沉为组件，例如受击、掉落、传送过滤器
- 若继续扩展玩法，建议把 `Level` / `World` 之间的场景规则再抽成 system 层，进一步减轻 `main.lua`
- 后续可把 LÖVE 临时启动器脚本固化为仓库内的测试命令，降低重复执行成本
- 下一步可继续把 `Level:randomizeEdges()` 的规则拆成可测试的纯逻辑
- 若后续要做升级系统，建议把 `power_up_ui.lua` 的选项与效果数据化
