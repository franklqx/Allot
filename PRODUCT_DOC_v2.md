# Allot — 产品功能文档 v4

**版本：** v0.4
**平台：** iPhone（iOS 26+）
**UI 语言：** English（所有用户界面）
**文档语言：** 中文
**最后更新：** 2026-04-22

> **本版主要改动（相对 v3）**
> 1. **导航改为 3 Tab**：Home / Focus / Allotted，同一条 Liquid Glass bar 上。右侧独立 `+` FAB。Settings 在右上角 ⚙
> 2. **取消顶部下拉 Timer** 交互——Timer 独立为 **Focus tab**
> 3. **Allotted 页彻底重做**：去除 donut，改为 3D 等距**长方体图（Prism Chart）**；右上角 Filter 内含 `View by Tag / By Task` 切换
> 4. **Task 色按时长动态排名分配**（Robinhood Strategies 式），Top 5 + "Others"
> 5. **Tag 默认预置 6 个**（Work/Health/Learn/Life/Hobby/Leisure）+ 系统 Untagged
> 6. **Onboarding 扩展**：Step 2 选 Tag，Step 3 选每 Tag 下的常见 Task 样板
> 7. **设计风格改为 Apple 原生中性色**：纯白/纯黑背景、黑白按钮、苹果系统文字色。彩色**只**留给 Allotted 长方体和列表色方块。参考 Robinhood 2024 rebrand + Origin
> 8. **没有全局 accent 色**——计时中数字不染色，只用字重和呼吸动画区分
> 9. **红色仅保留在 Delete 按钮**，日历 / 游标 / 今天标记一律不染红

---

## 一、产品定位

Allot 是一款面向个人用户的时间记录与分配工具。

不是待办清单，不是番茄钟。它解决一个具体问题：

> **"今天过完了，我不知道自己的时间去了哪里。"**

用户在 Allot 里做三件事：

1. **规划**：今天要做哪些事
2. **记录**：执行时计时；不想计时的（睡觉、吃饭、娱乐）可以快速补录
3. **回看**：今天/本周/本月/本年，时间被哪些任务和类别吃掉了

**核心哲学**：**记录而不评判**。不催你完成任务，不奖励"打勾数"，只如实呈现时间分配。

**视觉哲学**：chrome 纯中性色（白/黑/灰），**色彩只留给数据本身**。

---

## 二、目标用户

**核心用户**：独立开发者、自由职业者、多项目创业者

**用户特征**：
- 同时推进 2-5 个项目
- 容易沉浸单一任务，不知不觉几小时过去
- 想知道真实时间投入
- 没耐心搞复杂系统

**不是目标用户**：需要团队协作 / Kanban / 客户账单的用户

---

## 三、核心概念（数据模型）

### 3.1 Task（任务）

**Task 是长期对象，不是一次性条目。** 每天看到的"任务"是 Task 在那天的"出现"，由其类型和重复规则决定。Task 的执行记录是 Session（Task 1 → Session N）。

**Task 分两种类型**：

| 内部值 | UI 标签 | 用途 | 例子 |
|---|---|---|---|
| `once` | **Task** | 一次性安排 | 今天写 PRD、明天看牙医 |
| `recurring` | **Recurring** | 周期性重复 | 每天健身、每周冥想 |

**字段**：

| 字段 | 说明 | 必填 |
|---|---|---|
| title | 任务名 | 是 |
| type | `once` / `recurring` | 是（默认 `once`） |
| scheduledDate | once 的安排日期 | once 必填 |
| startTime | 开始时间 hh:mm | 否 |
| timerMode | `stopwatch` / `countdown` | 是（默认 `stopwatch`） |
| countdownDuration | 倒计时时长（秒） | 否 |
| repeatRule | 重复规则 | recurring 必填 |
| tagId | 关联的 Tag（单选） | 否（默认 Untagged） |
| completedDates | 已完成日期集合 | 否 |
| completedDuration | 完成时确认时长（秒） | 否 |

**repeatRule 选项**：
`everyDay` / `everyWeekday` / `everyWeekend` / `weekly` / `monthly` / `yearly` / `custom`

> 第一版全部免费开放。

**"完成"语义**（每天独立）：
- 完成 = **那一天**的"我今天不想再管它了"
- Recurring 明天继续出现，Once 折叠或灰显
- 已完成 Session 完全保留，进入 Allotted
- 随时可"取消完成"

### 3.2 Tag（标签）

**数据模型单级**：Task → Tag（多对一）。**不引入二级标签表**——二级视觉通过 Allotted 页面 By Tag / By Task 切换实现。

| 字段 | 说明 |
|---|---|
| id | UUID |
| name | Tag 名 |
| color | 12 色预设之一（见 DESIGN.md §2.3） |
| isSystem | 系统标签标志（仅 Untagged） |
| sortOrder | Settings → Tags 里的排序 |
| isPreset | 是否为预置 Tag（Onboarding 默认创建） |

**系统 Untagged**：
- 安装时自动创建，**不可删 / 改名 / 改色**
- 颜色固定 `#8A8F96`（Gray）
- 所有未指定 Tag 的 Task / Session 自动归入
- Allotted By Tag 模式下永远排最后

**预置 6 个 Tag**（Onboarding 默认全部创建，用户可关/改/删）：

| Tag | 色 | 默认建议 Task |
|---|---|---|
| **Work** | Sky `#5BB2E8` | Main job, Side project, Meetings, Deep work |
| **Health** | Lime `#A8C66C` | Strength, Cardio, Yoga, Meditation, Sleep |
| **Learn** | Lilac `#B084F5` | Reading, Language, Course, Coding practice |
| **Life** | Marigold `#F5B950` | Chores, Cooking, Commute, Family, Social |
| **Hobby** | Rose `#EFB0C0` | Music, Writing, Photo, Games, Outdoors |
| **Leisure** | Teal `#7DB6B0` | TV, Phone scroll, Video |

- 删除 Tag 不删 Task，关联 Task 转 Untagged
- Tag 删除确认弹窗带"本操作将把 N 个任务移入 Untagged"
- 用户 Tag 颜色限 12 色预设选一，**自定义 HEX 为 Pro**

### 3.3 Session（时间记录段）

| 字段 | 说明 |
|---|---|
| startAt | UTC 时间戳 |
| endAt | UTC（running 为 nil） |
| totalPausedSeconds | 暂停总时长（不计入有效） |
| source | `liveTimer` / `manualEntry` / `quickLog` |
| quickLogSubtype | `manual` / `completion` / `sleepHealth` |
| workTask | 关联 Task；可为 nil |

**有效时长** = `(endAt - startAt) - totalPausedSeconds`

`quickLog` 的 startAt/endAt 由用户填的时长反推（默认从当天 00:00 开始），不参与重叠检测。

---

## 四、导航结构

```
App
├── Home（Tab 1，左）
│   ├── 左上：日期两行；右上：⚙ Settings
│   ├── 日期条（Mon-Sun 7 天/页）
│   ├── 任务列表（按 startTime 早→晚；无时间续末尾）
│   ├── Hide / Show completed 切换
│   └── 底部 Tab Bar 共用
│
├── Focus（Tab 2，中）
│   ├── 大字时钟（纯数字，不染色）
│   ├── Task selector（pick a task to start）
│   ├── Stopwatch / 倒计时档位滑切换
│   ├── Pause / Stop
│   └── 底部 Tab Bar 共用（计时中保留可见）
│
├── Allotted（Tab 3，右）
│   ├── 顶部：Title + 时间范围 segment（Day/Week/Month/Year）+ 右上角 Filter 图标
│   ├── Prism Chart（3D 等距长方体横排）
│   ├── 下方列表（左侧色方块 + 名 + 时长 + %）
│   └── 点长方体 → 选中态 + 下方列表聚焦 / 弹 Task 面板
│
├── Tab Bar 底部：
│   [ Home  Focus  Allotted ] 三 Tab 共享 Liquid Glass 胶囊 + 右侧独立 [ + ] FAB
│
├── 任务面板（点 Home 行 / 点 Allotted Task 长方体触发）
│   ├── Once → 短面板（Complete / Edit / Remove）
│   └── Recurring → 垂直滚动 sheet（统计 + dot calendar）
│
├── 月历弹层（统一组件）
├── 横向滑尺（统一时间输入组件）
├── 快速补录滑尺
├── 新建任务全屏页（点 + FAB 触发）
└── Settings 页（点右上角 ⚙ 触发）
```

**关键变化**：
- **v3 的"顶部下拉 Timer"交互全部删除**——Timer 现在是独立的 Focus tab
- Tab 顺序 **Home → Focus → Allotted**，Focus 居中强调"记录动作是核心"
- `+` FAB 独立于 Tab 胶囊，挂在 overlay，永远可点

---

## 五、Home 页

### 5.1 顶部栏

```
┌──────────────────────────────────┐
│  Sunday                       ⚙  │
│  April 19                         │
└──────────────────────────────────┘
```

- **左上**：当前选中那天的日期，两行（星期粗体大字 / 月日次行）
  - 选中今天 → "Sunday / April 19"
  - 点击 → 弹统一月历（§10.1）
- **右上**：⚙ Settings
- **没有红点 / Today 文字标记**

### 5.2 日期条（7 天/页）

- **Monday-Sunday**（默认；Settings 可改）
- 横向滑动一次翻整 7 天
- 选中日：黑底白字（Light）/ 白底黑字（Dark）胶囊
- 今天但未选中：数字下方有一个**黑色/白色实心小圆点**（**不染红**）
- 行内表头：MON TUE WED THU FRI SAT SUN

### 5.3 月历选择器入口
见 §10.1。选某天 → 跳转 + 月历关闭。跳转后右下 `+` FAB 变 **`Today`** 文字按钮。

### 5.4 任务行

**单行结构**：

```
[图标] Task name                            20:05
```

| Task 类型 + 状态 | 图标 | 文字颜色 |
|---|---|---|
| Recurring · 未完成 | **虚线圆圈** `circle.dashed` | `text/primary` |
| Recurring · 已完成 | **虚线圆圈 + ✓** | `text/tertiary` |
| Once · 未完成 | **实线方框** `square` | `text/primary` |
| Once · 已完成 | **☑** `checkmark.square.fill` | `text/tertiary` |

**右端**：
- 有 startTime → SF Mono `text/tertiary`
- 无 startTime → 留白
- 进行中 → 左侧出现 2pt 竖线 + 右端 SF Mono 实时数字跳动（**不染色**，靠字重区分）
- 已完成且有时长 → `✓ 1h 30m`

**Tag 不在 Home 显示**——Tag 只在 Task 面板 / Allotted 页里出现。

**排序**（不显示分隔线）：
1. 有 startTime 的 → 早→晚
2. 无 startTime 的 → 续末尾，按创建时间

**两种点击**：
- **短按** → 弹 Task 面板（§5.5）
- **长按** 1 秒 + haptic → **直接开始计时**（跳转 Focus tab + Session 自动绑定）

### 5.5 任务面板

#### 5.5.1 Once Task 面板（短面板）

短按 Once 触发；不可上拉展开。

```
┌──────────────────────────────────────┐
│              ── (拖拽条)              │
│                                       │
│  运动                                 │
│  Apr 19, 2026  ·  20:05               │
│  ▇ Health                             │  ← 色方块 + Tag 名
│                                       │
│  Worked  1h 23m                       │
│                                       │
│  [ ✓ Complete ] / [ ↺ Incomplete ]    │
│  [ ✎ Edit ]                           │
│  [ ✕ Remove ]                         │  ← 红字
└──────────────────────────────────────┘
```

**规则**：
- 无 startTime → 第二行只显示日期
- Untagged → 不显示色方块行
- 无 Session → 不显示 Worked

**Complete 分支**：
- 有 Session → 直接完成，保留时长
- 无 Session → 弹横向滑尺补录（§10.2）→ 写入 quickLog → 标完成
- 已完成 → 按钮变 `↺ Incomplete`

#### 5.5.2 Recurring Task 面板（滚动 sheet）

默认 1/3，上滑至 2/3（封顶不全屏）。

```
┌──────────────────────────────────────┐
│              ── (拖拽条)              │
│                                       │
│  Recurring                            │
│  Exercise                             │
│  ▇ Health  ·  32% of #Health          │
│                                       │
│  [ ✎ Edit ]   [ ✕ Remove ]            │
│                                       │
│  ──────────── 分割 ────────────       │
│                                       │
│    4h 23m       18h 05m      47h 23m  │
│    This week    This month   Total    │
│                                       │
│  ──────────── 分割 ────────────       │
│                                       │
│  April 2026          5 of 30 days     │
│                                       │
│  ● ○ ○ ○ ○ ○ ○                        │
│  ● ● ● ○ ○ ○ ○                        │
│                                       │
│  ──────────── 分割 ────────────       │
│                                       │
│  ⓘ Statistics                         │
│  Average per day        24m           │
│  Average per week       2h 50m        │
│  Longest session        1h 45m        │
│  Share within #Health   32%           │
│  Share of daily logged  6%            │
└──────────────────────────────────────┘
```

**无 Complete 按钮**（Recurring 不完成，只记录时间）。

**dot calendar 二元**：有 Session = Tag 色实心；无 = 灰空心；点某点显示当天时长。

### 5.6 快速补录（Quick Log）

触发：Once 无记录点 Complete → 自动弹。

**滑尺**：§10.2，游标颜色 `text/primary`（**不红**）。

**默认值**：上一次该任务 quickLog 的时长；首次 1h 0m。

### 5.7 Hide / Show completed

**A. 展开（默认）**：已/未完成混排；底部胶囊 "Hide completed"
**B. 折叠**：只未完成；底部状态条 "Completed 2 of 5 ⟳"

用户可在 Settings 改默认。

### 5.8 空状态

时钟图标 + "No tasks yet" + "Tap + to add your first task"

---

## 六、Focus Tab（替代 v3 的下拉 Timer）

Focus 是一个**独立的 Tab 页**，不再是下拉手势。

### 6.1 idle 状态（未计时）

```
┌──────────────────────────────────┐
│ Focus                         ⚙  │
│                                   │
│                                   │
│             00:00                 │ ← SF Mono 88pt Light
│                                   │
│          Stopwatch                │ ← 当前档位名
│                                   │
│  ◀︎ 滑动切换：Stopwatch · 15min · 25min · 45min · 1h ▶︎
│                                   │
│  Pick a task to start             │
│  ┌─────────────────────────────┐  │
│  │ ○ Workout          07:00    │  │
│  │ ○ Read             09:00    │  │
│  │ ☐ Buy groceries    18:00    │  │
│  │ ○ Write code       20:05    │  │
│  │ ○ Random thinking           │  │
│  │ + New task                  │  │
│  └─────────────────────────────┘  │
│                                   │
│        [ Start ]                  │ ← 黑底白字大按钮
└──────────────────────────────────┘
```

**交互**：
- **数字下方左右滑** → 切 Stopwatch / 15min / 25min / 30min / 45min / 1h / 2h 档位
- 每档切换：轻震动 + 数字微弹
- **Task selector**：滚动列表，点选则绑定；`+ New task` 现场开一个极简输入框（仅 title）
- **Start 按钮**：未选 task → 以 `workTask = nil` 开始，计时结束弹归属确认（§6.4）

### 6.2 running 状态（计时中）

```
┌──────────────────────────────────┐
│ Focus                         ⚙  │
│                                   │
│                                   │
│            00:45:12               │ ← 数字粗体，呼吸动画
│                                   │
│  ▇ Work · Design Home UI          │
│  Today: 1h 23m  ·  Total: 24h    │
│                                   │
│                                   │
│       [⏸ Pause]   [⏹ Stop]         │
└──────────────────────────────────┘
```

- 数字**不染色**，只用 `.semibold` 字重 + 每秒呼吸动画（scale 1.00→1.01）强调"running"
- Tag 色方块出现在任务名左边
- 底部 Tab Bar 保持可见（不沉浸）——切到 Home/Allotted 仍能看到 Tab bar 上 Focus 图标轻微呼吸
- 倒计时模式下数字倒数，到 0 继续往上（变正计时），不自动停

### 6.3 Focus 子页：沉浸全屏（可选）

idle 或 running 都可从右上角 `arrow.up.left.and.arrow.down.right` 进入**沉浸全屏**：

```
┌──────────────────────────────────┐
│  ✕                          Stop  │
│                                   │
│                                   │
│            00:45:12                │ ← 超大字号 120pt
│           Today: 1h 23m            │
│                                   │
│              [⏸ Pause]              │
└──────────────────────────────────┘
```

- 全屏沉浸
- 自动息屏延迟 15 分钟
- ✕ 退出回常规 Focus 页
- Stop 结束 + 弹 §6.5 确认

### 6.4 未绑定任务的计时

- 点 Start 未选 task → 开始（`workTask = nil`）
- 时钟下方显示 "Untagged session"
- Stop 时弹：
  ```
  What was this for?
  [+ New task]  [Pick existing ▾]  [Save without task]
  ```

### 6.5 倒计时温和提醒

到 0 时：
1. 震动 + 推送 "You set 1h. Keep going?"
2. 通知两按钮：**Keep going** / **Stop now**
3. 不点默认继续（转正计时）

回 App 时检测"超设定 + 未回应"：
```
You planned 1h. The timer ran for 2h 15m.
Were you actually working that whole time?
[Yes, log 2h 15m]
[No, log just 1h]
[Custom: ____]
```

### 6.6 Stop 后的轻量确认

```
┌──────────────────────────────────┐
│ Recorded 1h 05m on               │
│ "Design Home UI"                  │
│                                   │
│ [Edit duration]  [Mark done]  [Save] │
└──────────────────────────────────┘
```

- 2 秒不操作 → 自动 Save
- < 30s 的 Session → 直接问 "Discard?"

### 6.7 跨页面持续

- 计时中切到 Home / Allotted：
  - Tab Bar 上的 Focus 图标轻微呼吸
  - 回 Focus tab 计时仍在
- 锁屏：Live Activity / Dynamic Island（Phase 2）
- App 被杀：UserDefaults 哨兵恢复（§11.4）

---

## 七、新建任务页面

从右下 `+` FAB 触发，**全屏页**。点 ✕ 或下拉关闭。

### 7.1 顶部 Tab 切换

```
┌──────────────────────────────────────┐
│  ✕              Recurring   [Task]   │  ← Task 默认
│  ──────────────────────────────────  │
│                                       │
│  Task title                           │  ← 大字输入
│                                       │
│                                       │
│  [ Today ]  [ Add time ]  [ Stopwatch ]  [ # Tag ]  │
│                                       │
│  ┌──────────── Add ─────────────┐    │
│  └─────────────────────────────────┘  │
└──────────────────────────────────────┘
```

- 左 `Recurring` / 右 `Task`，居中并列；点击或左右滑切换
- 默认 = `Task`
- 切换 Tab 时 title 保留

### 7.2 Task 模式字段

| Pill | 默认 | 点击 |
|---|---|---|
| `[ Today ▾ ]` | 当前查看日 | 弹月历（§10.1） |
| `[ Add time ]` | 无 | 弹滑尺（时刻 hh:mm） |
| `[ Stopwatch ▾ ]` | Stopwatch | 切 Stopwatch / Countdown；Countdown 时追加 `[ Duration ]` |
| `[ Duration ]` | — | 仅 Countdown 时，滑尺（时长） |
| `[ # Tag ]` | Untagged | 弹 Tag 列表（见 Settings Tag 列表样式） |

**底部**：`Add` 大胶囊按钮（`text/primary` 底 / `bg/primary` 字，即黑底白字 Light）

### 7.3 Recurring 模式字段

| Pill | 默认 | 点击 |
|---|---|---|
| `[ Every day ▾ ]` | Every day | 弹 Repeat 选项（§7.4） |
| `[ Add time ]` | 无 | 每日固定提醒时间 |
| `[ Stopwatch ▾ ]` | Stopwatch | 同 Task |
| `[ # Tag ]` | Untagged | 同 Task |

### 7.4 Repeat 选项

```
Repeat
─────────────────────
○ Every day                       ●
○ Weekly on Sunday
○ Monthly on Apr 19, 2026
○ Yearly on April 19
○ Every weekday
○ Every weekend
○ Custom...
```

### 7.5 Magic Input（Pro · Phase 2）

底部 pill 最左 `[ ✨ Magic input · Pro ]`。自然语言 → AI 解析结构化字段。第一版不实现。

### 7.6 默认值

- Tab：Task
- Date：当前查看日
- Time：无
- Timer mode：Stopwatch
- Tag：Untagged

---

## 八、Allotted 页面

**彻底重做**：去除 donut，改用 3D 等距**长方体图（Prism Chart）**。

### 8.1 顶部

```
┌──────────────────────────────────────┐
│  Allotted                        ⚙   │
│                                       │
│  [ Day | Week | Month | Year ]   ⚙   │ ← 时间范围 + Filter 图标
└──────────────────────────────────────┘
```

- 左：页面标题 "Allotted"
- 右：⚙ Settings 入口
- 下方一行：左边时间范围 segment；右边 **Filter 图标**（`line.3.horizontal.decrease.circle`），带 sticky 状态指示小圆点

**时间范围规则**：
- By Tag 模式：Day / Week / Month / Year 全开
- By Task 模式：**只支持 Day / Week**（Month/Year 自动灰禁或隐藏 → 用户若切到这两个 → 自动转 By Tag）

默认选中 **Week**。

### 8.2 Prism Chart（核心视觉）

```
Week · By Tag
─────────────────────────────────────────
    ╱─────────────╱  ╱──────╱ ╱──╱ ╱╱
   ╱             ╱  ╱      ╱ ╱  ╱ ╱╱
  ├───────────────┼─────────┼────┼─┤
  │ Work          │ Health  │Learn│...│
  └───────────────┴─────────┴────┴─┘
   Sky (47%)      Lime(26%) Lilac ...
```

- 横排 3D 等距长方体，宽度 = 时长占比
- 高度固定 64pt
- 顶面/侧面 1pt 浅线勾透视
- 颜色：By Tag 用 Tag 固定色；By Task 用排名动态色
- 段间 2pt gap
- 占比极小（< 3%）的段保留**最小宽度 16pt**以便可见
- 超过容器宽度 → 不滚动，合并尾部成 "Others"（见 §8.4）

**顶部总时长**：

```
42h 18m
this week
```

位置：Prism Chart 上方居中，`display/xl` SF Mono + `body/sm` 副标题

### 8.3 下方列表

Prism Chart 下方列该范围内的 Tag / Task（随 View 切换）：

```
┌──────────────────────────────────────┐
│ ▇ Work              12h 30m   47%  › │
│ ▇ Health             6h 45m   26%  › │
│ ▇ Learn              3h 12m   12%  › │
│ ▇ Hobby              2h 08m    8%  › │
│ ▇ Leisure            1h 20m    5%  › │
│ ▇ Untagged           0h 30m    2%    │
└──────────────────────────────────────┘
```

- 左侧色方块 14×14pt，对应该 Tag / Task 色
- 名 + 时长（SF Mono）+ 百分比（SF Mono）
- 右箭头 `chevron.right`（可 drill 的）
- Untagged / Others 无箭头（不可 drill）
- 点击行 = 等同点击对应长方体

### 8.4 Top 5 + Others（仅 By Task 模式）

By Task 模式按时长降序显示前 5 个 task，其余合并成 **"Others"** 一个长方体（Gray）。

| 排名 | 色 |
|---|---|
| 1 | Sky `#5BB2E8` |
| 2 | Amber `#F89C58` |
| 3 | Rose `#EFB0C0` |
| 4 | Lilac `#B084F5` |
| 5 | Lime `#A8C66C` |
| Others | Gray `#8A8F96` |

点 Others → 弹 sheet 列出被合并的所有 task（同 §8.3 列表样式）。

> **为什么 Top 5**：用户的核心关切是"今天/这周哪 4-5 件事吃掉了我的时间"。6 个以上数量，长方体变窄不好看，信息价值也递减。

### 8.5 By Tag ↔ By Task 切换

**入口**：右上角 Filter 图标 → 展开 Filter Menu（iOS Menu 样式）。

```
Filter
─────────────────────
View by
   ○ Tag
   ● Task           ← 默认
─────────────────────
Task type
   ● All
   ○ Recurring
   ○ Task (Once)
─────────────────────
Tags (By Tag 模式生效)
   ● Work         ＝ －
   ● Health       ＝ －
   ● Learn        ＝ －
   ● Life         ＝ －
   ● Hobby        ＝ －
   ● Leisure      ＝ －
   ○ Untagged     ＝
─────────────────────
[ Reset ]
```

**View by 默认 = Task**（因为 By Tag 前提是用户给 task 分过类；默认 Task 更通用）。

**Sticky**：用户一旦切换过，记住选择，不 reset 到默认。存 UserDefaults。

### 8.6 点击 Prism 行为

**By Tag 模式**：
- 点 Work 长方体 → **Work 段保持实心居中不动**，其他段**从实心变空心线框**（保留颜色 1pt 边框）并**左右退让 4pt**
- 同时下方列表滚动/过滤到 Work 下的 task 子列表：

```
        Work           12h 30m (47%)
─────────────────────────────────────
▇ Main job             8h 00m   64%
▇ Meetings             2h 30m   20%
▇ Side project         1h 20m   11%
▇ Deep work            0h 40m    5%
```

- 子列表的色方块用该 Task 排名动态色
- 再次点 Work（或点别处）→ 回到默认视图

**By Task 模式**：
- 点 task 长方体 → 其他退让成线框
- **弹出 Task 面板**（Once 短面板 / Recurring 滚动 sheet，同 Home）
- 关闭面板 → 回默认视图

**点 Others**：弹 sheet 列所有被合并 task

### 8.7 空状态

该范围无任何 Session：
- 一个浅灰描边空盒（占位长方体）
- 中央文案 "No data yet" + "Start tracking to see your patterns"

### 8.8 Untagged 提示

By Tag 模式下 Untagged 占比 > 30%：
- Prism Chart 下方显示横条提示
- "Tag your time to see clearer patterns"

---

## 九、Settings

从 Home / Allotted 右上角 ⚙ 进入。iOS Grouped List 风格。

### 9.1 General

| 项目 | 类型 | 默认 |
|---|---|---|
| Appearance | System / Light / Dark | System |
| Default timer mode | Stopwatch / Countdown | Stopwatch |
| Default countdown | 15min / 25min / 30min / 45min / 1h / 2h | 25min |
| Haptic feedback | On / Off | On |
| Week starts on | Monday / Sunday | Monday |
| Default completed view | Show / Hide | Show |

### 9.2 Tags（子页）

```
Settings → Tags
─────────────────────────────
+ New tag
─────────────────────────────
▇ Work          ＝  ›
▇ Health        ＝  ›
▇ Learn         ＝  ›
▇ Life          ＝  ›
▇ Hobby         ＝  ›
▇ Leisure       ＝  ›
▇ Untagged          ›       ← 系统标签
```

- 拖拽 ＝ 排序
- 点击行 → Tag 编辑页：Name / Color（12 色网格）/ Default timer / Default countdown / Delete
- Untagged：仅可查看下属 Task 数量，无编辑入口

**色板布局**：4×3 网格，12 色（见 DESIGN.md §2.3）

### 9.3 Notifications

| 项目 | 说明 |
|---|---|
| Task time reminder | 设了 startTime 的任务到点提醒 |
| Countdown end alert | "你设定 1h，是否继续？" |
| Weekly summary | 周日晚 19:00 推送（Phase 2） |
| Untracked time prompt | 空白时段提示补录（Phase 2） |

### 9.4 Pro / Upgrade

**Pro 功能（Phase 2 起逐步）**：
- Apple Health 集成（自动同步睡眠）
- 数据导出（CSV / JSON）
- 自定义 Tag 颜色
- 高级统计
- 多设备 iCloud
- Apple Watch 完整功能
- Magic Input（AI 自然语言新建任务）
- Filter 记忆

**免费版**：完整 Home / Focus / Allotted / 计时 / 补录 / 提醒；Repeat 全规则；深色模式。

### 9.5 Data & Privacy

- 全部本地存储
- 数据导出（Pro）
- 清除所有数据（带确认）
- 隐私政策链接

### 9.6 About

版本号 / 反馈 / 评分 / 致谢

---

## 十、统一交互组件

### 10.1 月历选择器

```
┌──────────────────────────────────┐
│              ── (拖拽条)          │
│                                   │
│  Apr 2026          ‹ Today ›      │
│                                   │
│   M   T   W   T   F   S   S       │
│                   1   2   3   4   │
│   5   6   7   8   9  10  11       │
│  12  13  14  15  16  17  18       │
│ [19] 20  21  22  23  24  25       │  ← 选中：黑底白字胶囊（Light）
│  26  27  28  29  30               │
└──────────────────────────────────┘
```

- **今天**：外圈 `text/primary` 1pt 描边（**不染红**）
- **选中**：实心胶囊，黑底白字（Light）/ 白底黑字（Dark）
- ‹ › 翻月；Today 回当月
- 点某天 → 选中并关闭
- 当月有记录的日期底部加小实心点

**统一用于**：New Task Date、Home 跳日期、长期任务统计跳月、Settings 数据导出范围

### 10.2 横向滑尺

```
┌──────────────────────────────────┐
│                                   │
│              Start time           │
│              20:05                │
│                                   │
│  ─ ─ ─ ─ ─ │ ─ ─ ─ ─ ─ ─        │
│            ↑                       │
│           游标 text/primary        │
└──────────────────────────────────┘
```

**两种模式**：
- **Time of day**：0:00-23:59，5 分钟一档（startTime）
- **Duration**：0-12h，5 分钟一档（countdownDuration / quickLog）

**交互**：
- 拖动 → 数字平滑变化
- 每 tick light haptic
- 触底 / 触顶强震

**游标颜色 `text/primary`**（黑/白跟主题），**不再用红色**（v3 已废弃）。

**应用场景**：New Task / Once 补录 / 长按 Done / Stop 后 Edit duration

### 10.3 Tag 调色板

12 色固定预设，4×3 网格。详见 DESIGN.md §2.3。自定义色为 Pro。

### 10.4 任务面板 Sheet

| Once | Recurring |
|---|---|
| 短面板固定高度 | 滚动 sheet 1/3 → 2/3 封顶 |
| Complete / Edit / Remove | Edit / Remove + 统计 |
| 不可上拉 | 上拉到 2/3 内部继续滚动 |

### 10.5 全局手势

| 手势 | 触发 |
|---|---|
| 短按任务行 | 弹任务面板 |
| 长按任务行 | 直接开始计时（跳 Focus） |
| Focus idle 数字左右滑 | 切 Stopwatch / 倒计时档位 |
| 横向滑动日期条 | 翻 7 天 |
| 长方体 tap | Prism 选中 + 下方聚焦 / 弹面板 |
| 上拉 sheet | Recurring 面板 1/3 → 2/3 |

**已删除手势**（v3 有 v4 无）：
- ❌ 顶部下拉触发 Timer（Focus 改为独立 tab）
- ❌ 再下拉触发 Focus 全屏（改为页内按钮进入）

---

## 十一、计时器引擎

### 11.1 状态机

```
idle → [Start] → running → [Pause] → paused → [Resume] → running
                    ↓                              ↓
                  [Stop]                         [Stop]
                    ↓                              ↓
                  ended（Session 保存到 SwiftData）
```

### 11.2 全局唯一
- 同一时刻只有一个 Session running
- 已有 A 在跑，启动 B → "Stop 'A' first?"

### 11.3 后台 / 锁屏
- 切走或锁屏：计时不停
- Live Activity / Dynamic Island（Phase 2）

### 11.4 App 被杀恢复
- 开始 Session 时立即写 `{taskId, startAt}` 到 UserDefaults
- 重开检查：若 UserDefaults 有 activeSession 但 SwiftData 无对应 running → 弹：
  > "Your timer for '[Task]' was still running. Save with end time now?"
  > [Save] [Discard]

### 11.5 跨零点
- Stop 时若 startAt 在昨天、endAt 在今天 → 自动拆两条
- 特殊（App 被杀跨零点）：不拆，归到开始日期

### 11.6 时区
- startAt / endAt 存 UTC，显示本地时区

---

## 十二、数据规则

| 规则 | 说明 |
|---|---|
| Session 重叠 | 不允许（quickLog 除外） |
| 跨日 | Stop 时自动拆 |
| 时区存储 | UTC |
| 时间归属 | startAt 本地时间归属 |
| 最小 Session | 无限制 |
| Quick Log 精度 | 5 分钟；默认 = 上次 quickLog 时长（首次 1h） |
| Tag 删除 | 不级联；关联 Task 转 Untagged |
| Untagged | 系统标签，不可删 / 改色 / 重命名 |
| Task 删除 | 级联删 Session |
| 全局唯一 running Session | 是 |
| App 被杀恢复 | UserDefaults 哨兵 + 弹窗 |
| Done 状态 | 仅 Once；Recurring 无 |

---

## 十三、首次使用引导（Onboarding）

约 90-120 秒，4 步。

**Step 1 — Welcome**
- 大标题 "Where did your time go?"
- 一句话定位 + Get started

**Step 2 — Pick your tags**
```
Pick the categories you'll track
(you can change these anytime)

☑ Work           ▇ Sky
☑ Health         ▇ Lime
☑ Learn          ▇ Lilac
☑ Life           ▇ Marigold
☑ Hobby          ▇ Rose
☑ Leisure        ▇ Teal

[ + Add custom ]

[ Continue ]
```

- 默认 6 个**全部勾选**
- 可取消勾选不创建；可 `+ Add custom` 加自定义 tag（选 12 色中一个）
- Skip 也可（所有 task 暂归 Untagged）

**Step 3 — Pre-populate tasks**（新增）

```
Start with some common tasks
(we'll create these for you — edit or delete anytime)

Work
  ☑ Main job
  ☑ Side project
  ☐ Meetings
  ☐ Deep work

Health
  ☑ Strength
  ☐ Cardio
  ☑ Meditation
  ☐ Sleep

Learn
  ☐ Reading
  ☑ Coding practice
  ...

[ Skip ]    [ Continue ]
```

- 只显示 Step 2 勾选了的 Tag
- 每 Tag 下列出预置 Task，默认勾 2-3 个
- Continue → 批量创建这些 Task（全部 Recurring / Stopwatch / 无 startTime）
- Skip → 不创建任何预置 Task

**Step 4 — Try the timer**

- "Tap Focus to start your first timer"
- 动效引导指向 Tab Bar 中间的 Focus 图标
- Done → 进入 Home

---

## 十四、Design System

详见 **DESIGN.md v0.2**。核心要点：

### 14.1 底色
- Light `#FFFFFF` / Dark `#000000`（纯白 / 纯黑）
- 文字用 iOS 系统 label / secondaryLabel / tertiaryLabel
- **没有全局 accent 色**

### 14.2 按钮
- Primary：黑底白字（Light）/ 白底黑字（Dark）
- Secondary：systemGray6 底
- Destructive：透明底 + systemRed 字（**唯一使用红色的地方**）

### 14.3 数据色（12 色）
只用于：Allotted 长方体、Task Row Tag 色方块（Home 不出现）、Tag 列表色方块、Dot Calendar 实心点

### 14.4 字体
- 正文 SF Pro
- 数字 SF Mono
- 不用 Bold，最重 Semibold

### 14.5 圆角
- 任务行 14pt、按钮 10pt / 胶囊、Sheet 顶 20pt
- **Prism 长方体无圆角**（硬边 + 1pt 透视线）

### 14.6 Liquid Glass
- Tab Bar 用系统原生 iOS 26 TabView，不自定义背景
- 各 Sheet 用 `.regularMaterial` 模糊

---

## 十五、Phase 2 平台扩展

- Dynamic Island / Live Activity
- Home Screen Widget（小 + 中）
- Apple Watch 伴侣 App（只读 + 暂停）
- 每周总结推送
- 未记录时段提醒条
- Day Review 弹层
- Siri Shortcuts

---

## 十六、路线图

### Phase 1（MVP）

**核心功能**
- Home 页（日期条 + 月历 + 任务行 + 排序 + 任务面板 + Hide/Show + `+` FAB）
- 长按开始计时、短按弹面板
- Task 类型：Once / Recurring
- Once 短面板 / Recurring 滚动 sheet
- 新建任务全屏（Tab 切换 + pill 行 + 横向滑尺）
- **Focus 独立 Tab**（idle task selector + 左右滑档位 + running 呼吸动画 + 沉浸全屏子页）
- Stop 后轻量确认
- Quick Log（无记录 Complete + 长按 Done + 横向滑尺）
- 倒计时温和提醒
- 未绑定任务计时
- **Allotted Prism Chart**（By Tag / By Task 切换 + Top 5 + Others 合并 + 下方列表 + drill-down）
- Tag 系统（系统 Untagged + 12 色预设 + Settings → Tags + 6 个预置 Tag）
- 月历选择器（统一组件）
- 横向滑尺（统一组件）
- Settings 全套（General / Tags / Notifications / Data / About）
- 深色模式（System / Light / Dark）
- App 被杀恢复
- **Onboarding 4 步**（含 Tag 选择 + Task 预置创建）

### Phase 2
- Allotted 月/年视图细化
- Live Activity / Dynamic Island
- Widget
- Apple Watch
- 未记录提醒条
- 每周总结
- 数据导出（Pro）
- Apple Health 集成（Pro）
- 自定义 Tag 颜色（Pro）
- 高级统计（Pro）
- Magic Input（Pro）
- Filter 记忆（Pro）

### Phase 3
- 锁屏 Widget
- iCloud 同步

### Phase 4
- iPad
- macOS

---

## 十七、技术约束

| 约束 | 说明 |
|---|---|
| 最低 iOS | **26+**（Liquid Glass TabView，glass effect） |
| 最低 watchOS | 11+（Phase 2） |
| 数据存储 | SwiftData 本地 |
| 共享机制 | App Group |
| 计时精度 | 1 秒，存毫秒级时间戳 |
| 隐私 | 全部本地（Phase 1-2） |
| 隐私清单 | PrivacyInfo.xcprivacy |
| Haptic | UIImpactFeedbackGenerator |

---

## 十八、待办 TBD

1. Prism 长方体透视角度（等距 30° 还是 35°，等真机试色）
2. Tag 编辑页色板布局微调（4×3 vs 6×2）
3. Onboarding Step 3 每个 Tag 下预置 Task 清单最终定稿
4. Pro / Upgrade 页完整布局
5. 空状态插画（或无插画方案）
6. 12 色 Dark 模式精确降饱和比例（真机校色）
7. App Icon 最终设计（白底 3D 立方体线框方向）
8. Focus 沉浸全屏的横屏支持与否

---

**v0.4 | 2026-04-22 | 重写导航为 3 Tab + Focus 独立 + Allotted Prism Chart**
