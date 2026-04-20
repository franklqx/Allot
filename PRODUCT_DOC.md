# Allot — 产品功能文档

**版本：** v0.1  
**平台：** iPhone（iOS 17+）  
**语言：** 英文（所有用户界面）  
**最后更新：** 2026-04-17

---

## 一、产品定位

Allot 是一款面向个人用户的时间记录与分配工具。

它不是待办清单，也不是番茄钟。它解决一个具体问题：

> **"今天过完了，我不知道自己的时间去了哪里。"**

用户在 Allot 里做三件事：

1. **规划**：今天有哪些任务，每个任务打算投入多久。
2. **记录**：执行时开始计时，结束时停止。忘记开始的可以事后补录。
3. **回看**：今天、本周、本月，时间被哪些任务和类别吃掉了。

---

## 二、目标用户

**核心用户：**

- 独立开发者（同时推进多个 App）
- 自由职业者（需要对客户汇报时间）
- 多项目创业者（容易沉浸在某一块，忽略其他）

**用户特征：**

- 同时推进 2-5 个项目
- 容易沉浸在单个任务里，不知不觉几个小时过去了
- 想要知道真实的时间投入，不满足于只打勾"完成"
- 对复杂系统没有耐心，想要快速上手、每天真的打开用

**不是目标用户：**

- 需要团队协作功能的企业用户
- 需要项目管理看板（Kanban）的用户
- 需要客户账单记录的自由职业者（不做发票/计费功能）

---

## 三、核心概念（数据模型）

### 3.1 Task（任务）

Task 是 Allot 里最基本的单位。

**一个 Task 包含：**

| 字段 | 说明 | 必填 |
|------|------|------|
| 标题 (title) | 任务名称，如 "Design Home UI" | 是 |
| 目标时长 (targetDuration) | 这件事打算做多久（秒），如 3600 = 1小时 | 否 |
| 是否重复 (isRecurring) | true = 每周重复出现；false = 一次性 | 是（默认 false）|
| 重复日 (recurringDays) | 哪几天重复。[1,2,3,4,5] = 工作日，[6,7] = 周末，[] = 每天 | 仅重复任务 |
| 具体日期 (scheduledDate) | 一次性任务安排在哪天 | 仅一次性任务 |
| 具体时间 (scheduledTime) | 安排在几点开始（只用时间部分）| 否 |
| 标签 (tags) | 附加的标签列表（多对多）| 否 |

**Task 的分类逻辑：**

- 有 `scheduledTime` 的任务 → 出现在对应时间段（AM 或 PM 区块）
- 没有 `scheduledTime` 的任务 → 出现在"Unscheduled"区块
- AM = 00:00–11:59；PM = 12:00–23:59

**Task 没有"完成状态"（已勾选/未勾选）：**

Allot 关注的是"你在这件事上投入了多少时间"，而不是"你有没有做完这件事"。Task 本身没有完成/未完成的概念，有的只是它关联了多少个 Session（时间记录段）。

---

### 3.2 Tag（标签）

Tag 是用户自定义的分类标签，可以贴在任意数量的 Task 上。

**一个 Tag 包含：**

| 字段 | 说明 |
|------|------|
| 名称 (name) | 如 "Work"、"Side Project"、"Health"、"Personal" |
| 颜色 (color) | 可选，HEX 颜色值，如 "#FF6B6B"。不设颜色则为默认样式 |

**Tag 的关系规则：**

- 一个 Tag 可以贴在多个 Task 上（多对多）
- 一个 Task 可以有多个 Tag
- 删除 Tag 不会删除 Task（Task 只是不再关联这个 Tag）

**Tag 的用途：**

Insights 页面的数据按 Tag 汇总。例如：你有两个 Task 都贴了 "Work" 标签，Insights 会把它们合并显示为 "Work" 类别的总时长。

---

### 3.3 Session（时间记录段）

Session 是一段具体的时间记录，代表"我在某任务上从几点做到几点"。

**一个 Session 包含：**

| 字段 | 说明 |
|------|------|
| 开始时间 (startAt) | Session 开始的时间戳（UTC 存储） |
| 结束时间 (endAt) | Session 结束的时间戳。如果正在计时，endAt 为空 |
| 暂停总时长 (totalPausedSeconds) | 该 Session 里累计暂停了多少秒（不计入有效时长）|
| 来源 (source) | `liveTimer`（正计时）或 `manualEntry`（补录）|
| 关联任务 (workTask) | 这个 Session 属于哪个 Task |

**有效时长的计算：**

```
有效时长 = (endAt - startAt) - totalPausedSeconds
```

**Session 的生命周期：**

```
[空闲] --开始--> [计时中] --暂停--> [已暂停] --继续--> [计时中]
                    |                              |
                    +--------结束--> [已结束，保存到 SwiftData] <--+
```

---

## 四、导航结构

```
App
├── Home（底部 Tab 1）
│   ├── 日期导航栏（顶部）
│   ├── 日期滑动条
│   ├── 当天概览条（已记录时长 / 未记录时长）
│   ├── 正在进行中的任务卡（有计时时固定显示）
│   ├── AM 区块（上午任务列表）
│   ├── PM 区块（下午任务列表）
│   ├── Unscheduled 区块（无时间安排的任务）
│   └── 右下角 FAB（+  /  Today）
│
├── Insights（底部 Tab 2）
│   ├── 维度切换（Day / Week / Month / Year）
│   ├── 圆环图（时间分配）
│   └── 分类排行列表
│
├── Calendar 弹层（从 Home 顶部图标触发）
│
├── 补录界面（从"Log Time"按钮或提醒条触发）
│
├── 新建/编辑 Task 界面（从 + 按钮触发）
│
└── 新建/编辑 Tag 界面
```

---

## 五、Home 页

Home 是用户每天打开 App 最先看到的页面，也是最高频的操作页。

### 5.1 顶部导航栏

**内容：**
- 中间：当前查看的日期，格式 "Thursday, Apr 17"
- 右侧：日历图标按钮，点击弹出 Calendar 月历弹层

**状态：**
- 查看今天：日期显示为 "Today, Apr 17" 或直接显示日期
- 查看历史/未来日期：显示对应日期

---

### 5.2 日期滑动条

位于导航栏正下方，横向滚动。

**功能：**
- 显示前后各几天的日期（如：周一至下周一）
- 当前选中日期高亮
- 滑动切换日期，Home 内容同步更新
- 今天的日期有特殊标记（如加粗或下方小点）
- 有 Session 记录的日期显示小圆点（灰色或彩色）

---

### 5.3 当天概览条

位于日期滑动条下方，一行数据摘要。

**内容：**
- 今天已记录总时长，如 "3h 24m tracked"
- 今天有 Session 记录的 Task 数量（可选）

**逻辑：**
- 只统计今天（所选日期）内结束的 Session
- 跨越今天（当前还在计时中的 Session）不计入，直到结束
- 查看历史日期时，显示那天的已记录时长

---

### 5.4 正在进行中的任务卡（Active Timer Card）

**触发条件：** 有一个 Session 正在计时（状态为"running"）。

**位置：** 固定在 AM / PM 区块上方，始终可见。

**内容：**
- 左侧：3pt 蓝色竖条（颜色：#0071e3）
- 任务名称（粗体）
- 下方：状态文字 "Running" 或 "Paused"
- 右侧：实时计时器，格式 "1:24:07"（蓝色，等宽字体，每秒刷新）
- 暂停按钮
- 结束按钮

**交互：**
- 点击卡片整体：展开/进入 Task 详情
- 点击暂停：Session 进入暂停状态，计时器停止计数，totalPausedSeconds 开始计算
- 点击结束：弹出确认（或直接结束），endAt = 当前时间，Session 保存到 SwiftData

---

### 5.5 AM / PM 区块

**AM 区块：** 显示今天所有 scheduledTime 在 00:00–11:59 的 Task。  
**PM 区块：** 显示今天所有 scheduledTime 在 12:00–23:59 的 Task。

**区块不显示的条件：** 该时段没有任何 Task，则整个区块不展示（不占位置）。

**区块内的 Task 排序：** 按 scheduledTime 升序排列。

---

### 5.6 Task 行（列表项）

**默认状态（折叠）：**
- 任务名称（粗体）
- 如有目标时长：下方显示 "45 min goal" 或 "2 hr goal"（灰色小字）
- 如果该 Task 今天已有 Session 记录：显示已记录时长，如 "32m logged"
- 行右侧：开始按钮（▶）

**展开状态（点击任务行后展开）：**
- 同上内容
- 下方增加三个操作按钮：
  - **Start**（主按钮，深色填充）：开始正计时
  - **Log Time**（次按钮，描边）：打开补录界面，手动填入时间段
  - **Done**（弱按钮，透明）：标记这个 Task 今天已完成（不再在列表前端显示，归入底部）

**正在计时状态（该 Task 有正在运行的 Session）：**
- 任务名称前有蓝色脉冲圆点
- 右侧显示已计时时长（实时更新）
- 展开后显示暂停 / 结束按钮

**已有记录但非进行中：**
- 任务名称正常显示
- 下方显示已记录时长

---

### 5.7 Unscheduled 区块

显示今天所有没有 scheduledTime 的 Task（包括：没设时间的一次性任务，以及今天是重复日但没有设时间的重复任务）。

区块标题：**"UNSCHEDULED"**（全大写）

**内容与 Task 行相同，交互完全一致。**

---

### 5.8 空状态

**当天没有任何 Task（全新用户，或当天没有安排）：**
- 屏幕中间：时钟图标（大）
- 标题："No tasks yet"
- 副文字："Tap + to add your first task"

**当天有 Task 但某个区块为空：** 不显示该区块，不显示空状态提示。

---

### 5.9 FAB（右下角悬浮按钮）

**状态 1：查看今天**
- 图标：加号（+）
- 样式：深色液态玻璃圆形按钮
- 点击：弹出新建 Task 的界面

**状态 2：查看历史/未来日期**
- 文字："Today"
- 样式：同上
- 点击：日期滑动条跳回今天，Home 内容切换到今天

---

### 5.10 未记录提醒条（Untracked Time Banner）

**触发条件：** 系统发现今天有连续超过 30 分钟（可配置）的空白时段（既没有 Session 记录，也没有在计时），且现在是当天的某个时间节点（如下午或晚上）。

**位置：** 列表底部，Unscheduled 区块之后，FAB 之上。

**内容：** "You have 2h 15m untracked today. Add a record?"

**点击行为：** 打开补录界面，自动预填最长的空白时间段。

**这个功能不是惩罚性的：** 文案是中性提示，不带感叹号、不用红色。

---

## 六、新建 / 编辑 Task 界面

从 FAB（+）点击后以底部弹层形式出现。

### 6.1 字段

| 字段 | UI 控件 | 说明 |
|------|---------|------|
| 任务名称 | 文本输入框 | 必填，弹出键盘后自动聚焦 |
| 目标时长 | 时长选择器（或分段选择：无/15分/30分/45分/1h/2h/自定义）| 可选 |
| 时间安排 | 分段：No time / Specific time | 是否设定今天的具体开始时间 |
| 具体时间 | 时间选择轮盘（hh:mm）| 仅"Specific time"时显示 |
| 重复设置 | 开关 + 日期选择器 | 打开后选择重复日 |
| 标签 | 多选标签列表 | 显示已有 Tag，可多选；末尾有"+ New Tag"选项 |
| 日期归属 | 日期（默认为当前查看日期）| 一次性任务 |

### 6.2 交互

- 保存：点击"Add"或"Save"按钮，Task 写入 SwiftData，弹层关闭，Home 列表更新
- 取消：点击"Cancel"或向下拖动弹层
- 编辑已有 Task：点击 Task 行上的"编辑"入口（长按或滑动显示），进入同一界面，字段预填当前值

---

## 七、补录界面（Manual Time Entry）

补录指用户事后手动填写"我在 XX 时间段做了 XX 任务"。

**触发方式：**
1. Task 展开后点击"Log Time"按钮
2. 点击"未记录提醒条"
3. 新建 Session 时选择"Add past record"

### 7.1 界面结构

**顶部：**
- "Log Time" 标题
- 日期选择（默认今天，可切换）
- 取消 / 保存按钮

**中间（核心操作区）：**
- 时间轴可视化：一条横轴，显示开始时间和结束时间
- 开始时间：大号数字，可拖动调整
- 结束时间：大号数字，可拖动调整
- 计算出来的时长：实时显示 "1h 30m"

**下方：**
- 选择关联任务：
  - 如果从 Task 行的"Log Time"打开，已自动绑定该 Task
  - 如果从其他入口打开，显示任务选择列表
- 快速分类（无需关联任务时）：Break / Meal / Commute / Other
  - 选择快速分类后，系统创建一个同名临时 Task，或归入通用分类

**最下：**
- "Save" 按钮（全宽，主色）

### 7.2 时间轴拖动交互

- 拖动开始时间的把手，或拖动结束时间的把手
- 时间以 5 分钟为最小单位吸附（快速拖动时以 15 分钟吸附）
- 每次吸附到节点时有轻震动（light haptic）
- 时间不能重叠（如果该时段已有 Session 记录，显示冲突提示）
- 时间不能跨日（只能在当天范围内）

### 7.3 重叠检测

- 新建 Session 的时间段如果与已有 Session 重叠：高亮冲突区域，提示"This overlaps with [Task Name]"
- 不允许保存有重叠的 Session

---

## 八、Calendar 弹层

Calendar 不是独立页面，是从 Home 顶部日历图标触发的一个底部弹层。

### 8.1 打开方式

点击 Home 顶部导航栏右侧的日历图标。

### 8.2 内容

**顶部：**
- 当前月份（如 "April 2026"）
- 左右箭头切换月份

**月历网格：**
- 标准 7 列日历网格
- 今天的日期有特殊标记（圆圈或下划线）
- 当前选中日期高亮
- 有 Session 记录的日期显示小圆点（表示"那天有记录"）
- 无记录的日期和将来日期样式相同（不做区分）

### 8.3 交互

- 点击某天：弹层关闭，Home 内容切换到该天
- 向下拖动弹层：关闭，回到 Home

---

## 九、计时器引擎（TimerService）

计时器是 Allot 的核心逻辑，规则如下：

### 9.1 状态机

```
idle（空闲）
  ↓ 用户点击 Start
running（计时中）
  ↓ 用户点击 Pause        ↓ 用户点击 Stop / 点击 Done
paused（已暂停）           ended（已结束，Session 保存）
  ↓ 用户点击 Resume
running（计时中）
  ↓ 用户点击 Stop
ended（已结束，Session 保存）
```

### 9.2 同一时刻只能有一个 Session 在运行

- 当已有 Task A 在计时时，用户点击 Task B 的 Start：
  - 弹出提示："Stop 'Task A' first?"
  - 选项：Stop Task A and start Task B / Cancel
- 不允许两个 Session 同时处于 running 状态

### 9.3 进入后台时的行为

- 用户切换到其他 App 或锁屏：计时不停，Session 继续计时（系统记录 startAt，不需要轮询）
- 计时中的任务通过 Dynamic Island / Lock Screen 显示实时时长

### 9.4 App 被系统杀死后的恢复

**机制：** 每次 Session 开始时，立即将 `{taskId, startAt}` 写入 UserDefaults（App Group 容器，key: `activeSession`）。

**恢复流程：** 用户重新打开 App → 检查 UserDefaults 中是否有 `activeSession` → 如果有，且 SwiftData 中没有对应的 running Session → 弹出提示：

> "It looks like your timer for '[Task Name]' was still running.  
> Save with end time now?"
>
> - **Save** — 以当前时间作为 endAt，创建 Session 保存
> - **Discard** — 清除 UserDefaults，放弃这段记录

### 9.5 跨零点的 Session 处理

- 如果一个 Session 的 startAt 在今天，endAt 在明天：
  - 保存时自动拆分为两个 Session：
    - Session 1：startAt = 原开始时间，endAt = 23:59:59（今天）
    - Session 2：startAt = 00:00:00（明天），endAt = 原结束时间
  - Insights 按各自归属日期统计
- 特殊情况（App 被杀跨越零点）：不拆分，直接用恢复时的当前时间作为 endAt，归入开始日期

### 9.6 时区

- Session 的 startAt 和 endAt 统一存为 UTC
- 所有显示（Home 日期、Insights 图表）使用用户本地时区
- 用户换时区旅行时：历史记录按当时的本地时间显示（以存储的 UTC 转换当前本地时区）

---

## 十、Insights 页

Insights 是用户定期查看"我把时间给了什么"的页面。

### 10.1 时间维度

顶部有分段控制器，可切换：**Day / Week / Month / Year**

---

### 10.2 Day（当日视图）

**圆环图：**
- 显示当天按 Tag 分类的时间占比
- 每个 Tag 对应一段弧，颜色来自 Tag 的颜色设置（无颜色的 Tag 用默认灰色序列）
- 无法归入任何 Tag 的时间段（Task 没有 Tag 的 Session）显示为"Other"
- 未记录时间不在圆环里显示（圆环只统计有记录的时间）
- 圆环中心显示当天已记录总时长

**Tag 排行列表：**
- 按时长降序排列
- 每行：颜色圆点 + Tag 名 + 时长 + 进度条（相对于最大的 Tag 的比例）
- 最后一行：如有无 Tag 的 Session，合并显示为 "Other"

---

### 10.3 Week（本周视图）

**柱状图：**
- 7 根柱，代表周一至周日
- 每根柱的高度 = 当天总记录时长
- 柱的颜色分段：按 Tag 拆分（堆叠柱状图）

**Tag 排行列表：**
- 与 Day 相同，但统计本周所有 Session
- 每行额外显示：每天平均时长

---

### 10.4 Month（本月视图）

**折线图或柱状图：**
- X 轴：本月每天（或每周）
- Y 轴：总记录时长
- 多条线（或堆叠柱）分别对应不同 Tag

**Tag 排行列表：**
- 与 Week 相同，统计范围为本月

---

### 10.5 Year（本年视图）

**柱状图：**
- 12 根柱，代表 1-12 月
- 每根柱高度 = 当月总记录时长
- 颜色分段：按 Tag

**Tag 排行列表：**
- 统计范围为本年

---

### 10.6 点击 Tag 查看详情（Phase 2）

点击任一 Tag → 进入 Tag 详情页：
- 该 Tag 下所有 Task 的列表
- 每个 Task 的累计时长
- 近 30 天的时长趋势折线图

---

## 十一、标签（Tag）管理

### 11.1 创建 Tag

入口：
1. 新建/编辑 Task 时，标签选择区末尾的"+ New Tag"
2. 未来可在设置页面的 Tags 管理区域创建

**创建流程：**
- 输入 Tag 名称
- 可选：选择颜色（色盘，12-16 个预设颜色）
- 保存

### 11.2 编辑 Tag

- 修改名称：已关联该 Tag 的所有 Task 同步更新
- 修改颜色：Insights 里对应颜色变化

### 11.3 删除 Tag

- 删除 Tag 不删除相关 Task
- 已关联该 Tag 的 Task，Tag 关系断开，Task 本身继续存在
- 已有的 Session 也不受影响
- 弹出确认："Delete tag '[Name]'? Tasks won't be deleted."

---

## 十二、平台扩展功能

### 12.1 Dynamic Island（灵动岛 / Live Activity）

**触发：** 用户开始计时，Live Activity 自动启动。

**紧凑模式（Compact）：**
- 左侧：任务名称（截断最多 10 个字符）
- 右侧：实时计时器 "1:24:07"

**展开模式（Expanded，长按灵动岛）：**
- 任务名称
- 实时计时器（大字体）
- 暂停按钮
- 结束按钮

**结束：** 用户点击结束，或 App 内结束，Live Activity 消失。

**最长时长：** iOS 限制 Live Activity 最多持续 8 小时，8 小时后自动降级显示（不更新）。

---

### 12.2 Home Screen Widget（主屏幕小组件）

提供两种尺寸：

**Small（小组件 2x2）：**
- 应用名"Allot"（小字）
- 今天已记录时长（大字，如 "5h 24m"）
- 当前进行中任务（如果有）：任务名 + 实时计时器
- 没有正在计时：显示今天记录的 Task 数量

**Medium（中组件 4x2）：**
- 左半边：今天总记录时长 + 进行中任务（同 Small）
- 右半边：Top 3 Tag 的时长（Tag 颜色圆点 + 名称 + 时长）

**数据来源：** Widget Extension 从 App Group 共享容器读取：
- 实时计时器：读取 UserDefaults 中的 `activeSession.startAt`，自己计算 `now - startAt`（使用 `Text(date, style: .timer)` 无需轮询，系统自动更新）
- 历史 Session 数据：读取 App Group 里的 SwiftData 持久化文件

**点击 Widget 行为：**
- 点击整体：打开 App，跳转到 Home 今日视图
- 点击进行中任务（如有）：打开 App，聚焦到正在计时的 Task

---

### 12.3 Apple Watch 伴侣 App（Phase 1：只读 + 暂停）

**主界面：**
- 当前进行中任务名称
- 实时计时器（每秒刷新）
- 暂停按钮
- 结束按钮

**没有进行中任务时：**
- 显示今天已记录时长
- "Open iPhone app to start"

**数据同步：**
- Watch 通过 WatchConnectivity 与 iPhone 保持同步
- Watch 前台时使用 `sendMessage`（实时）
- Watch 后台时使用 `transferUserInfo`（延迟同步）

**从 Watch 暂停：**
- Watch 发送：`{"action": "pause", "sessionId": "uuid"}`
- iPhone 收到后：更新 Session 状态，记录暂停开始时间，通知 Watch 状态更新
- Watch 收到响应：更新 UI 显示"Paused"

**Phase 1 限制：** Watch 不能新建 Task，不能开始新 Session，不能切换任务。只能暂停/继续/结束当前任务。

**Phase 2 扩展：** Watch 上可以选择已有 Task 并开始计时。

---

### 12.4 每周总结推送通知

**触发时间：** 每周日晚上 19:00（本地时间）

**实现方式：** `UNCalendarNotificationTrigger`，在 App 启动时检查本周是否已安排通知，如果没有则立即安排。不需要服务器。

**通知内容：** （示例）
> **"Your week in Allot"**  
> This week: Work 13h, Side Project 7h, Health 3h

**跳过条件：** 如果本周总记录时长为 0，跳过发送（不推送空通知）。

**用户可在 iOS 通知设置里关闭此通知。**

---

## 十三、首次使用引导（Onboarding）

约 60 秒，三步引导，不可跳过前两步。

**第 1 步：创建第一个 Tag**
- 标题："Label your time"
- 副文字："Tags help you see where your time goes. Create one to get started."
- 默认建议：Work / Personal / Health（一键选择，也可自定义）

**第 2 步：创建第一个 Task**
- 标题："Add your first task"
- 副文字："What are you working on today?"
- 输入框预填当前时间的问候语（早上："What's your morning project?"）

**第 3 步：完成一次计时**
- 标题："Start the clock"
- 副文字："Tap Start to begin tracking. Tap Stop when you're done."
- 动画演示计时器启动

**完成：** 引导结束，进入正常 Home 页。

---

## 十四、数据规则汇总

| 规则 | 说明 |
|------|------|
| Session 重叠 | 不允许。新 Session 的时间段与已有 Session 重叠时，拒绝保存，提示冲突 |
| 跨日 Session | 在保存时（点击 Stop）自动拆分为两条 Session，按各自归属日期统计 |
| 时区存储 | startAt / endAt 统一存为 UTC，显示时转换到本地时区 |
| 时间归属 | Session 按 startAt 的本地时间归属到对应日期 |
| 最小 Session 时长 | 无最小值限制（5 秒的 Session 也可保存）|
| 补录时间精度 | 5 分钟吸附（快速拖动时 15 分钟）|
| Tag 删除 | 不级联删除 Task |
| Task 删除 | 级联删除所有关联 Session |
| 同时只能有一个运行中的 Session | 全局唯一，不允许两个 Task 同时计时 |
| App 被杀恢复 | 用 UserDefaults 哨兵值恢复，弹出确认弹窗 |

---

## 十五、功能路线图

### Phase 1（MVP，当前目标）

- Home 完整页面（日期导航、AM/PM/Unscheduled 区块、Task 行展开交互）
- Task 创建、编辑、删除
- Tag 创建、编辑、删除、多选关联
- 正计时（Start / Pause / Resume / Stop）
- 补录（手动填写时间段）
- Session 保存到 SwiftData（本地持久化）
- 日期滑动条 + Calendar 弹层
- 当天概览（已记录时长）
- 未记录时段提醒条
- Insights 日视图（圆环 + Tag 排行）
- Dynamic Island Live Activity
- Home Screen Widget（小 + 中）
- 每周总结推送通知
- Apple Watch 伴侣 App（只读 + 暂停）
- 首次使用引导
- App kill 恢复弹窗

### Phase 2

- Insights 完整视图（Week / Month / Year）
- 重复任务（每天/指定工作日/每周）
- 深色模式（App 内独立开关）
- 本地数据导出（JSON / CSV）
- Session 结束后添加反思笔记（可选文字，最多 500 字）
- Siri Shortcuts / AppIntents（"Hey Siri, start coding"）
- Day Review 弹层（晚间回顾时间轴，补录一整天）
- Apple Watch 从 Watch 端开始新 Session
- TelemetryDeck 数据打点（匿名，用于了解功能使用情况）

### Phase 3

- HealthKit 集成（专注时间 → Apple Health Mindful Minutes）
- 锁屏 Widget（Lock Screen Complication）
- Haptic 交互优化
- Today 按钮切换动画优化

### Phase 4

- 同步 / 云备份（iCloud 或服务端，依用户需求决定）
- iPad 版本
- macOS Catalyst 或原生 macOS 版本

---

## 十六、技术约束

| 约束 | 说明 |
|------|------|
| 最低 iOS 版本 | iOS 17+（SwiftData 要求）|
| 最低 watchOS 版本 | watchOS 10+（Live Activity on Watch 要求）|
| 数据存储 | SwiftData，本地持久化，不上云（Phase 1）|
| 共享机制 | App Group 共享容器，Widget / Watch / Live Activity 读取同一数据源 |
| 计时精度 | Timer 以 1 秒为最小精度，startAt 和 endAt 存储毫秒级时间戳 |
| 隐私 | 所有数据存本地，不上传任何服务器（Phase 1 / Phase 2）|
| App Store 要求 | 需要 PrivacyInfo.xcprivacy 隐私清单（iOS 17+ 审核要求）|
