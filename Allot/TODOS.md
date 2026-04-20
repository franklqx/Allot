# Allot — TODOS

生成自 /plan-ceo-review on 2026-04-16
分支: main

---

## P1 — 上线前必须完成

### [P1] PrivacyInfo.xcprivacy 隐私清单
**什么：** 创建 PrivacyInfo.xcprivacy，声明 App 对 UserDefaults、文件系统等 API 的使用。
**为什么：** iOS 17+ App Store 审核要求。缺少会被拒稿。
**估算：** XS（人工 1小时 / CC+gstack 10分钟）
**启动点：** Xcode → File → New → Resource → App Privacy

### [P1] TimerService 单元测试
**什么：** 测试状态机完整路径（idle→running→paused→running→ended）+ 重叠 session 拒绝逻辑 + 跨日 session 拆分逻辑。
**为什么：** 这是 App 的核心逻辑。没有测试的状态机在边界情况（App 被杀、重复点击、快速切换）会产生数据不一致。
**估算：** S（人工 2天 / CC+gstack 30分钟）
**启动点：** AllotTests.swift → 新增 TimerServiceTests class

### [P1] SwiftData 磁盘满时的错误处理
**什么：** ModelContext.save() 失败时捕获 NSError，显示用户友好的提示而不是 crash。
**为什么：** 当前 AllotApp.swift 的 fatalError 在生产环境会导致 App 崩溃。
**估算：** XS（人工 1小时 / CC+gstack 10分钟）
**启动点：** AllotApp.swift:22 — 替换 fatalError

### [P1] TimerService + SwiftData 耦合接口
**什么：** TimerService 是 App 生命周期单例，无法访问 View 的 @Environment(modelContext)。需要在 AllotApp.swift 初始化 TimerService 时传入 sharedModelContainer，TimerService 自建 ModelContext 用于写入 TimeSession。
**为什么：** 不解决此耦合，停止计时时数据无法持久化。这是 TimerService 实现的前提接口设计，合伙人需要在动手前确认方案。
**估算：** XS（接口设计讨论 15分钟 / 代码改动 5分钟）
**启动点：** AllotApp.swift → 初始化 TimerService 时传入 sharedModelContainer；TimerService.swift → init(container: ModelContainer)

### [P1] App Group 配置（Widget + Live Activity + Watch 前提）
**什么：** 在所有 targets（主 App、Widget Extension、Watch Extension）配置相同的 App Group identifier。
**为什么：** Widget、Live Activity 和 Watch 都需要读取 TimerService 写入的 UserDefaults 数据。App Group 是唯一共享机制。
**估算：** XS（人工 30分钟 / CC+gstack 10分钟）
**启动点：** Xcode → Project → Signing & Capabilities → + App Groups

---

## P2 — Phase 2 功能

### [P2] TelemetryDeck 简易指标接入
**什么：** 接入 TelemetryDeck SDK，打点：正计时 vs 倒计时使用率、每日启动频率、周通知点击率。
**为什么：** 有了外部用户之后，需要数据来决定 Phase 2 做什么。无 GDPR 问题，对独立开发者友好。
**估算：** S（人工 半天 / CC+gstack 15分钟）
**启动点：** https://telemetrydeck.com — 免费层足够

### [P2] Day Review 弹层（事后时间块归因）
**什么：** 当天结束时弹出竖向时间轴，用户拖拽时间块归因到项目。解决"忘记开始计时"场景。
**为什么：** 独立 AI 意见认为这是差异化点——让完全不追踪的用户通过"晚上60秒回顾"获得价值。
**估算：** M（人工 1周 / CC+gstack 2小时）
**依赖：** TimeSession.source (.manualEntry) 已经存在，数据层就绪。
**启动点：** PRODUCT_SPEC.md §11

### [P2] 任务完成后的反思笔记
**什么：** Session 结束后，可选输入一条简短文字（最多 500 字）。
**为什么：** 用户确认想要，但不是 MVP 核心。需要 TimeSession 增加 `note: String?` 字段。
**估算：** S（人工 1天 / CC+gstack 15分钟）
**启动点：** TimeSession.swift → add `var note: String?`

### [P2] Siri Shortcuts / AppIntents 集成
**什么：** "Hey Siri，开始写代码" → 自动开始指定任务的计时。
**为什么：** 零摩擦开始计时的终极形态。但需要核心 App 稳定后才有意义。
**估算：** S（人工 2天 / CC+gstack 30分钟）
**启动点：** AppIntents framework (iOS 16+)

### [P2] Insights 周/月/年视图
**什么：** 在当日占比之外，补齐 PRODUCT_SPEC §10 中的周/月/年维度。
**为什么：** Phase 1 只做当日，完整 Insights 是 Phase 2 的主要 feature。
**估算：** M（人工 1周 / CC+gstack 1.5小时）
**启动点：** PRODUCT_SPEC.md §10

### [P2] 深色模式开关
**什么：** App 内深色/浅色模式切换（当前跟随系统）。
**为什么：** PRODUCT_SPEC 的 Phase 2 条目。IndIe dev 用户群对深色模式需求高。
**估算：** S（人工 1-2天 / CC+gstack 30分钟）

### [P2] 本地备份/导出（JSON 或 CSV）
**什么：** 导出所有 Session 数据为 JSON 或 CSV。
**为什么：** 隐私友好（不上云），便于换机和自查。
**估算：** S（人工 1天 / CC+gstack 20分钟）

### [P2] Apple Watch 从 Watch 启动新 session
**什么：** 在 Watch App 上选择项目并直接开始计时（Phase 1 的 Watch 只支持查看+暂停）。
**为什么：** 完整的 Watch 体验，但 WCSession 复杂度需要主 App 稳定后再加。
**估算：** M（人工 1周 / CC+gstack 1.5小时）

---

## P3 — 未来

### [P3] HealthKit 集成
**什么：** 将"专注时间"记录到 HealthKit 的 Mindful Minutes。
**为什么：** PRODUCT_SPEC Phase 4 条目。让 Allot 的数据进入 Apple Health 生态。
**估算：** M（人工 1周 / CC+gstack 1小时）

### [P3] 小组件 (Lock Screen Complication)
**什么：** 锁屏小组件显示今日已记录时间 + 当前进行中任务。
**为什么：** Phase 3 PRODUCT_SPEC 条目。

### [P3] 重复任务
**什么：** 设定一个任务每天/每周重复出现在 Home。
**为什么：** Phase 2 PRODUCT_SPEC 条目（提前到 Phase 2），如果用户反馈强烈可提前。
