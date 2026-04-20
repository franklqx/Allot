# Allot — 产品功能文档 v3

**版本：** v0.3
**平台：** iPhone（iOS 17+）
**UI 语言：** English（所有用户界面）
**文档语言：** 中文
**最后更新：** 2026-04-19

> **本版主要改动（相对 v0.2）**
> 1. Task 类型重命名：UI 标签 `Recurring` / `Task`（替代 Long-term / Short-term）
> 2. 新建任务页参考新图：顶部 `Recurring | Task` 切换 + 底部 pill 行 + 大 Add 按钮 + 横向滑尺时间选择器
> 3. 移除 Reminder 字段；默认 timer mode = Stopwatch
> 4. Home 任务行：右端显示 start time；按时间从早到晚排序；无时间任务续在末尾；**不显示分隔线**
> 5. 任务行手势重定义：**短按** = 弹面板；**长按** = 直接开始计时
> 6. Once 任务面板：含 Tag / start time / Worked / `Complete ↔ Incomplete` 切换；无记录直接 Complete → 弹滑尺补录
> 7. Recurring 任务面板：**垂直滚动**单页 sheet（不是分页）；3 核心数字 = This week / This month / Total；点阵日历 = binary + Tag 色（不做"强度"）；Statistics 含 average / longest / share within tag / share of daily logged
> 8. Allotted 页面：双 donut drill-down（Tag → Task）；环外悬浮标签；右上角漏斗 filter（Task Type + Tag display/hide）；Untagged 灰色段
> 9. 月历选择器：统一全 App 所有日期选择样式
> 10. Tag 管理：Onboarding 5 个种子可选；Tag 颜色 / 编辑放 Settings → Tags 子页（不在新建任务流里）
> 11. **深色模式**从 Phase 2 提到 Phase 1（System / Light / Dark 三选）
> 12. Magic Input（AI 自然语言新建）规划为 Pro，Phase 2 实现
> 13. 顶部 Timer 面板下拉时：列出今日任务，点选直接开始；含 + New 现场新增

---

## 一、产品定位

Allot 是一款面向个人用户的时间记录与分配工具。

不是待办清单，不是番茄钟。它解决一个具体问题：

> **"今天过完了，我不知道自己的时间去了哪里。"**

用户在 Allot 里做三件事：

1. **规划**：今天要做哪些事
2. **记录**：执行时计时；不想计时的（睡觉、吃饭、娱乐）可以快速补录
3. **回看**：今天/本周/本月，时间被哪些任务和类别吃掉了

**核心哲学**：**记录而不评判**。Allot 不催你做完任务，不奖励你"完成多少个"，只如实呈现时间分配。

---

## 二、目标用户

**核心用户**：独立开发者、自由职业者、多项目创业者

**用户特征**：
- 同时推进 2-5 个项目
- 容易沉浸单一任务，不知不觉几小时过去
- 想知道真实时间投入，不满足于打勾"完成"
- 没耐心搞复杂系统

**不是目标用户**：需要团队协作 / Kanban / 客户账单的用户

---

## 三、核心概念（数据模型）

### 3.1 Task（任务）

**Task 是长期对象，不是一次性条目。** 每天看到的"任务"是 Task 在那天的"出现"，由其类型和重复规则决定。Task 的执行记录是 Session（Task 1 → Session N）。

**Task 分两种类型（type）**：

| 内部字段值 | UI 标签 | 用途 | 例子 |
|---|---|---|---|
| `once` | **Task** | 一次性安排 | 今天写 PRD、明天看牙医 |
| `recurring` | **Recurring** | 周期性重复 | 每天健身、每周冥想 |

> ⚠️ "Task" 在 UI 上是 `once` 类型的标签，在数据模型层是所有时间事件的统称（含 once + recurring）。文档中用 **Once Task** / **Recurring Task** 消除歧义。

**字段**：

| 字段 | 说明 | 必填 |
|---|---|---|
| title | 任务名 | 是 |
| type | `once` / `recurring` | 是（默认 `once`） |
| scheduledDate | once 任务的安排日期 | once 必填 |
| startTime | 开始时间 hh:mm（用于 Home 排序与提醒） | 否 |
| timerMode | `stopwatch` / `countdown` | 是（默认 `stopwatch`） |
| countdownDuration | 倒计时时长（秒），仅 `countdown` 用 | 否 |
| repeatRule | 重复规则（见下） | recurring 必填 |
| tagId | 关联的 Tag（单选） | 否（默认 Untagged） |
| completedDates | 已完成日期集合（每天独立判定） | 否 |
| completedDuration | 完成时确认的时长（秒），来自 quickLog 补录 | 否 |

**repeatRule 选项**（参考图 3 风格）：
- `everyDay`
- `everyWeekday`（周一到周五）
- `everyWeekend`（周六周日）
- `weekly`（每周指定日）
- `monthly`（每月指定日）
- `yearly`（每年指定日）
- `custom`（自由勾选）

> Pro 限制策略待定，第一版全部免费开放。

**"完成"的语义（每天独立）**：
- 完成不是 Task 整体结束，而是**那一天**的"我今天不想再管它了"
- Recurring：今天完成 ≠ 明天不出现，明天还会出现
- Once：完成 = 折叠或灰显
- 已完成的所有 Session 数据**完全保留**，进入 Allotted 统计
- 随时可"取消完成"（Incomplete）

### 3.2 Tag（标签）

| 字段 | 说明 |
|---|---|
| name | Tag 名 |
| color | 12 色预设之一（自定义色为 Pro） |
| isSystem | 系统标签标志（仅 Untagged 为 true） |

**系统标签 Untagged**：
- App 安装时自动创建，**不可删除 / 重命名 / 改色**
- 颜色固定为浅灰
- 所有未指定 Tag 的 Task / Session 自动归入 Untagged
- 在 Allotted donut 中显示为灰色段
- 当 Untagged 占比 > 30% → donut 中心追加提示 "Tag your time to see clearer patterns"

**用户 Tag**：
- 多对多 → 改为**多对一**（一个 Task 仅一个 Tag），简化数据展现
- 删除 Tag 不删 Task，受影响 Task 自动转移到 Untagged
- Allotted 页按 Tag 汇总

### 3.3 Session（时间记录段）

| 字段 | 说明 |
|---|---|
| startAt | UTC 时间戳 |
| endAt | UTC，正在计时为 nil |
| totalPausedSeconds | 暂停总时长（不计入有效时长） |
| source | `liveTimer` / `manualEntry` / `quickLog` |
| quickLogSubtype | `manual`（长按 Done）/ `completion`（无记录直接 Complete）/ `sleepHealth`（Pro：Apple Health 同步） |
| workTask | 关联的 Task；可为 nil（未归属计时） |

**有效时长** = `(endAt - startAt) - totalPausedSeconds`

`quickLog` 的 startAt / endAt 由用户填的时长反推（默认从当天 00:00 开始；不参与重叠检测）。

---

## 四、导航结构

```
App
├── Home（液态玻璃 Tab Bar 左 1）
│   ├── 顶部：左侧日期两行 + 右上角 ⚙ 设置
│   ├── 日期条：Mon-Sun 固定 7 天/页
│   ├── 任务列表（按 startTime 早→晚 + 无时间续在末尾）
│   ├── Hide / Show completed 切换
│   └── 右下 + FAB（或 "Today" 按钮）
│
├── Allotted（液态玻璃 Tab Bar 左 2）
│   ├── 顶部：日期 + 设置 + 时间范围 segment
│   ├── Tag 维度 donut + 环外悬浮标签
│   ├── Chart / List 切换
│   └── Tag 段点击 → Drill-down 到 Tag 详情页（双 donut）
│
├── 底部：[Home | Allotted] 胶囊 + 右侧 + FAB
│
├── 顶部 Timer 面板（1/4 屏，从顶边下拉触发）
│   ├── 下拉时显示今日任务列表，点选开始 / + New 现场新增
│   └── 再下拉 → Focus 全屏沉浸模式
│
├── 任务面板（点任务行触发）
│   ├── Once → 短面板（含 Complete/Edit/Remove）
│   └── Recurring → 垂直滚动 sheet（含统计）
│
├── 月历弹层（统一样式，全 App 复用）
├── 横向滑尺（统一时间输入组件）
├── 快速补录滑尺（长按 Done / 无记录 Complete 触发）
├── 新建任务全屏页（点 + FAB 触发）
└── Settings 页（点右上角 ⚙ 触发）
```

---

## 五、Home 页

### 5.1 顶部栏

```
┌──────────────────────────────────┐
│  Sunday                       ⚙  │
│  April 19                         │
└──────────────────────────────────┘
```

- **左上角**：当前选中那天的日期，两行（星期粗体大字 / 月日次行）
  - 选中今天 → "Sunday / April 19"
  - 选中其他天 → 显示对应日期
  - 点击 → 弹出统一月历选择器（见 §10.1）
- **右上角**：⚙ 设置图标
- **没有红点 / 大号数字 / Today 文字标记**
- 顶部 Timer 下拉时，这两个元素**保持在原位**（覆盖在黑色面板上）

### 5.2 日期条（固定 7 天/页）

- **周一到周日**（默认；可在 Settings 改周起始日）
- 横向滑动一次翻整 7 天
- 当前选中日：圆角胶囊背景高亮 + 数字加粗
- 今天但未选中：数字下方有小红点
- 周内行内表头：MON TUE WED THU FRI SAT SUN

```
┌──────────────────────────────────────┐
│ [19]  20   21   22   23   24   25    │
│  SUN  MON  TUE  WED  THU  FRI  SAT   │
└──────────────────────────────────────┘
```

### 5.3 月历选择器入口

点击左上角日期 → 弹出统一月历选择器（详见 §10.1）。选某天 → 跳转到那天，月历关闭。
跳转后右下角 + 号变成 **"Today"** 按钮，点击回今天。

### 5.4 任务行

**单行结构**（一行装下，右端始终是 startTime 或留白）：

```
[图标] Task name                            20:05
```

**左侧图标根据 Task 类型切换**：

| Task 类型 + 状态 | 图标 | 文字颜色 |
|---|---|---|
| Recurring · 未完成 | **虚线圆圈** | 黑/白（随主题） |
| Recurring · 已完成 | **虚线圈 + ✓** | 灰 |
| Once · 未完成 | **实线方框 ☐** | 黑/白 |
| Once · 已完成 | **☑**（实方框打勾） | 灰 |

**右端**：
- 有 startTime → 浅灰 SF Mono 数字（如 `20:05`），右对齐
- 无 startTime → 留白
- 进行中 → 蓝色脉冲计时（`0:45:12`）
- 已完成且有时长 → `✓ 1h 30m`

**Tag 不在 Home 显示**——行内只显示通用图标，Tag 在任务面板里展示。

**排序规则**（不显示任何分隔线）：
1. 有 startTime 的任务 → **从早到晚**升序
2. 无 startTime 的任务 → 续在末尾，按创建时间升序

```
○  Workout                                 07:00
○  Read                                    09:00
☐  Buy groceries                           18:00
○  Write code                              20:05
○  Random thinking
☐  Email cleanup
```

**两种点击方式**：
- **短按行** → 弹出任务面板（见 5.5）
- **长按行**（约 1 秒，伴随震动） → **直接开始计时**（顶部 Timer 面板自动展开 + Session 自动绑定该 Task）

行内**不放开始按钮**——保持视觉简洁。

### 5.5 任务面板

#### 5.5.1 Once Task 面板（短面板）

短按 Once 任务行触发；不可上拉展开（已是全部内容）。

```
┌──────────────────────────────────────┐
│              ── (拖拽条)              │
│                                       │
│  运动                                 │
│  Apr 19, 2026  ·  20:05               │  ← 日期 · startTime
│  ● Health                             │  ← Tag 彩色点 + 名
│                                       │
│  Worked  1h 23m                       │  ← 仅在已记录时显示
│                                       │
│  [ ✓ Complete ] / [ ↺ Incomplete ]    │  ← 按状态切换
│  [ ✎ Edit ]                           │
│  [ ✕ Remove ]                         │  ← 红色
└──────────────────────────────────────┘
```

**字段显示规则**：
- 无 startTime → 第二行只显示日期
- 无 Tag（即 Untagged） → 不显示彩色点行（不刻意提示"未分类"在面板里，避免噪音）
- 无 Session → 不显示 Worked 行

**Complete 行为分支**：
- 任务有 Session 记录 → 直接标完成，保留全部时长
- 任务无 Session 记录 → 弹出**横向滑尺补录窗**（见 §10.2），让用户填"花了多久"，写入一条 `quickLog`（subtype = `completion`）的 Session，再标完成
- 已完成 → 按钮变 `↺ Incomplete`，点击恢复未完成（时长数据保留）

#### 5.5.2 Recurring Task 面板（垂直滚动 sheet）

短按 Recurring 任务行触发。底部 sheet **默认 1/3 高度**，**向上滑可拉到 2/3**（最大高度，不全屏 — 保留顶部约 1/3 让用户仍能看到当天任务背景）。所有内容垂直滚动一气呵成（不是分页）。

```
┌──────────────────────────────────────┐
│              ── (拖拽条)              │
│                                       │
│  Recurring                            │
│  Exercise                             │
│  ● Health  ·  32% of #Health          │  ← Tag + 在此 Tag 内时长占比
│                                       │
│  [ ✎ Edit ]   [ ✕ Remove ]            │  ← 无 Complete
│                                       │
│  ──────────── 分割 ────────────       │
│                                       │
│    4h 23m       18h 05m      47h 23m  │
│    This week    This month   Total    │  ← 3 核心数字
│                                       │
│  ──────────── 分割 ────────────       │
│                                       │
│  April 2026          5 of 30 days     │
│                                       │
│  ● ○ ○ ○ ○ ○ ○                        │
│  ● ● ● ○ ○ ○ ○                        │  ← 点阵日历
│  ○ ○ ○ ○ ○ ○ ○                        │
│  ... 上滑可见更多月份                  │
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

**默认露出（1/3 高度）**：标题 + Edit/Remove + 3 核心数字
**上滑展开（2/3 高度，最大）**：sheet 内部继续滚动，依次显露 dot calendar → statistics
**下滑**：先回 1/3，再下滑关闭

> ⚠️ 2/3 高度封顶，**不全屏**。保留顶部约 1/3 让背景任务列表可见，便于用户上下文切换。

**关键设计决策**：

- **无 Complete 按钮**：Recurring 不"完成"，只记录时间。每天若想标"今日 done"也只能通过长按 Done 形式补录时长（与 Once 不同：Recurring 的 Done 等同 quickLog 一条）

- **dot calendar 不做"强度"**：
  - 有 Session 的日子 = Tag 颜色实心点
  - 无 Session = 灰色空点
  - 点击某个点 → 小 popup 显示当天时长（如 "Apr 13 · 1h 12m"）
  - **理由**：不同任务的合理时长差距太大（健身 vs 睡眠 vs 写代码），强制定义"够不够"会引发焦虑，违背"无负担"理念。事实型呈现 + 在 Statistics 看 average 即可

- **"32% of #Health"**：本任务在所属 Tag 总时长里的占比，帮用户感知"我的健康时间主要花在哪个动作"

- **"Share of daily logged"**：本任务时长占用户每日总记录时长的百分比，反映该任务在生活中的权重

### 5.6 快速补录（Quick Log）

**两个触发入口**：

1. **长按任务行的 Done 区域**（如果列表里有 Done 按钮 — 当前未启用，保留扩展）
2. **Once 任务无记录时点击 Complete** → 自动触发

**滑尺组件**：见 §10.2 横向滑尺 + haptic（替代之前讨论的滚轮）。

**默认值**：
- 该任务上一次 quickLog 的时长
- 第一次记录该任务：1h 0m

**用例**：
- 一次性会议 → 短按 Done → 弹滑尺，默认 1h，调到 30m → Save
- 睡觉（如果设为 Recurring） → 长按 Done → 滑到 8h → Save
- 任务忘了开计时但已经做完 → 在面板点 Complete → 弹滑尺 → Save

### 5.7 完成态切换：Hide / Show completed

**默认**：Once 任务完成后留在列表中（带灰色 ✓ 和时长），按 startTime 顺序排列。

**两种切换状态**：

**A. 列表展开（默认）**
- 已完成 + 未完成混排
- 列表底部胶囊按钮 **"Hide completed"**
- 点击 → 折叠所有已完成 → 进入 B

**B. 折叠**
- 仅显示未完成
- 列表底部状态条 **"Completed 2 of 5 ⟳"**（带圆形进度环）
- 点击 → 重新展开 → 回到 A

**用户设置**：默认显示模式（Show / Hide）可在 Settings 改。

### 5.8 空状态

无任何任务时：
- 时钟图标
- "No tasks yet"
- "Tap + to add your first task"

### 5.9 底部导航（Liquid Glass Tab Bar）

```
┌──────────────────────────────────┐
│                                   │
│  [⬢ Home  ◐ Allotted]      [ + ]  │
│   ↑ 左侧胶囊（两个 Tab）   ↑ FAB
└──────────────────────────────────┘
```

- **左侧胶囊**：Home | Allotted 切换
- **右侧独立按钮**：
  - 看今天 → 图标 `+`，点击进入新建任务全屏页
  - 看其他日期 → 文字 `Today`，点击跳回今天
- **液态玻璃风格**：半透明磨砂、跟随内容色微变、圆角胶囊、浮在内容上

**Settings 入口**：右上角 ⚙（不在底部）。

### 5.10 未记录提醒条（Phase 2）

底部条："You have 2h 15m untracked today. Add a record?" → 点击进 Quick Log。

---

## 六、新建任务页面

从右下 + FAB 触发，**全屏页面**（不是底部弹层）。点 ✕ 或下拉关闭。

### 6.1 顶部 Tab 切换

页面顶部居中两个 Tab：

```
┌──────────────────────────────────────┐
│  ✕              Recurring   [Task]   │  ← Task 默认选中
│  ──────────────────────────────────  │
│                                       │
│  Task title                           │  ← 大字输入框
│                                       │
│                                       │
│                                       │
│  [ Today ]  [ Add time ]  [ Stopwatch ]  [ # Tag ]  │  ← pill 行
│                                       │
│  ┌──────────── Add ─────────────┐    │
│  └─────────────────────────────────┘  │
│  ─────── 键盘 ────────                │
└──────────────────────────────────────┘
```

- **Tab**：左 `Recurring`，右 `Task`，居中并列；点击或左右滑切换
- 默认进入 = `Task`
- 切换 Tab 时输入框文字保留

### 6.2 Task 模式字段

输入框上方 pill 行（可水平滚动）：

| Pill | 默认 | 点击行为 |
|---|---|---|
| `[ Today ▾ ]` | 当前查看日 | 弹出统一月历选择器（§10.1） |
| `[ Add time ]` | 无 | 弹出横向滑尺时间选择器（§10.2，时间模式 = 一天中具体时刻 hh:mm） |
| `[ Stopwatch ▾ ]` | Stopwatch | 切换 Stopwatch / Countdown；选 Countdown 时**自动追加** `[ Duration ]` pill |
| `[ Duration ]` | — | 仅当选 Countdown 出现，弹横向滑尺（时长模式） |
| `[ # Tag ]` | Untagged | 弹出 Tag 列表选择 |

**底部按钮**：`Add`（大胶囊按钮，显眼）

### 6.3 Recurring 模式字段

| Pill | 默认 | 点击行为 |
|---|---|---|
| `[ Every day ▾ ]` | Every day | 弹出 Repeat 选项列表（§6.4） |
| `[ Add time ]` | 无 | 每日固定提醒时间（hh:mm） |
| `[ Stopwatch ▾ ]` | Stopwatch | 同 Task 模式 |
| `[ # Tag ]` | Untagged | 同 Task 模式 |

**底部按钮**：`Add`

### 6.4 Repeat 选项弹层

底部 sheet 选项列表（参考图 3 风格，单选）：

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

第一版**全部免费开放**。Pro 限制策略后续再定。

### 6.5 Magic Input（Pro · Phase 2）

入口：底部 pill 行最左 `[ ✨ Magic input · Pro ]`。

**功能**：自然语言输入 → AI 解析为结构化字段。
**示例**：
- 输入："写代码每天晚上 9 点 1 小时"
- 解析：type=recurring · repeatRule=everyDay · startTime=21:00 · timerMode=countdown · countdownDuration=60min · suggestTag=Work

第一版不实现，Phase 2 上线，仅 Pro。

### 6.6 默认值

- Tab：Task
- Date：当前查看日
- Time：无
- Timer mode：Stopwatch
- Tag：Untagged

---

## 七、顶部 Timer 面板

### 7.1 视觉

```
┌──────────────────────────────────┐
│ Sunday                        ⚙  │ ← 日期 / 设置保持原位
│ April 19                          │
│                                   │
│           00:45:12                │ ← 纯数字大字（白）
│                                   │
│   ● Work · Design Home UI         │ ← Tag 点 + 任务名
│   Today: 1h 23m  ·  Total: 24h   │
│                                   │
│      [⏸ Pause]      [⏹ Stop]       │
└──────────────────────────────────┘
   ↓ 再下拉 → Focus 全屏  |  ↑ 上拉收起
```

**样式**：
- 占屏 1/4，全宽黑色背景
- 时钟字体：SF Mono / SF Pro 等宽，白色，约 64-72pt
- 不用翻页效果（避免视觉噪音），每秒平滑刷新
- 下方两行：第一行 Tag + 任务名；第二行 今日累计 + 该任务总累计
- 最下方：⏸ Pause / ⏹ Stop

### 7.2 触发逻辑

- **下拉手势**：从屏幕**顶部边缘**下拉触发
- **冲突避免**：列表不在顶端时，第一次下拉先回顶端，第二次才触发
- **全局可用**：Home 和 Allotted 都能下拉
- **上拉收起**：拖回去就收

### 7.3 下拉时的任务选择器（重点更新）

**当 Timer 处于 idle 状态**（无任务在跑）：

下拉 Timer 面板时，时钟下方出现**今日任务列表**：

```
┌──────────────────────────────────┐
│           00:00                   │ ← idle 时钟 0
│                                   │
│  Pick a task to start             │
│                                   │
│  ○ Workout            07:00       │
│  ○ Read               09:00       │
│  ☐ Buy groceries      18:00       │
│  ○ Write code         20:05       │
│  ○ Random thinking                │
│                                   │
│  [ + New task ]                   │
└──────────────────────────────────┘
```

- 点任意一行 → 时钟绑定该 Task 并开始计时
- 点 `+ New task` → 现场弹出极简输入框（仅 title），创建后立即开始计时（其他字段事后编辑）
- 已完成的任务也出现在列表（灰显），可点开始（产生新 Session）

**当 Timer 处于 running 状态**：直接显示 7.1 那样的运行视图，不再有任务选择器。

### 7.4 左右滑切换 Timer 模式（仅 idle 时）

idle 时钟显示 `00:00`，可左右滑切换：

```
[Stopwatch] ⇄ [15min] ⇄ [25min] ⇄ [30min] ⇄ [45min] ⇄ [1h] ⇄ [2h]
   默认            倒计时档位（25min = 番茄）
```

- 每滑一档：时钟翻动 + 轻震动
- 滑到底：触底震动反馈
- 默认停在 `Stopwatch`

**已在计时时**：不能再滑，只能 Pause / Stop。

### 7.5 未绑定任务的计时

- 点开始时未选 Task → 计时开始（workTask = nil）
- 时钟下方显示 "Untagged session"
- 结束时弹窗：
  ```
  What was this for?
  [+ New task]  [Pick existing ▾]  [Save without task]
  ```

### 7.6 Reminder Timer（倒计时）模式

**核心理念：温和提醒，不强制结束**

倒计时模式视觉与正计时一致，只是数字往下走。**没有 ±15s 微调，没有 Skip**。

**到点行为**：
1. 设备震动 + 推送 "You set 1h. Keep going?"
2. 通知里两个按钮：**Keep going** / **Stop now**
3. 不点也不会自动停，默认继续计时（变成正计时）

**回 App 时**（检测到"超过设定时长 + 没回应"）：
```
You planned 1h. The timer ran for 2h 15m.
Were you actually working that whole time?
[Yes, log 2h 15m]
[No, log just 1h]
[Custom: ____]
```

### 7.7 Focus 全屏专注模式

**触发**：在 1/4 屏面板上**再次下拉**。
**收起**：单指上拉。

```
┌──────────────────────────────────┐
│  ✕                          Stop  │
│                                   │
│            00:45:12                │ ← 超大字号（120pt+）
│           Today: 1h 23m            │
│                                   │
│              [⏸ Pause]              │
└──────────────────────────────────┘
```

- 黑底白字，全屏沉浸
- 自动息屏延迟 15 分钟（比系统默认长）
- 横竖屏均支持
- ✕ 退出回 1/4 屏面板（计时不停）
- Stop 直接结束 Session，触发 §7.9 确认弹窗

### 7.8 跨页面持续显示

- 计时进行中时，下拉触发的面板**保留状态**
- 切到 Allotted 也能下拉看到同一计时器
- 关闭 App 后通过 Live Activity / Lock Screen 继续可见（Phase 2）

### 7.9 Stop 后的轻量确认

```
┌──────────────────────────────────┐
│ Recorded 1h 05m on               │
│ "Design Home UI"                  │
│                                   │
│ [Edit duration]  [Mark done]  [Save] │
└──────────────────────────────────┘
```

- **2 秒不操作 → 自动 Save**
- **Edit duration**：弹滑尺调本次时长
- **Mark done**：保存 + 把 Task 标记今日完成
- **Save**：手动确认

**不弹确认的情况**：Session < 30 秒（直接问 "Discard?"）

---

## 八、Allotted 页面

### 8.1 顶部

- 左：页面标题 "Allotted"
- 右：⚙ 设置入口
- 下方：时间范围 segment `[ Day | Week | Month | Year ]`，默认 Week

### 8.2 主 Donut（Tag 维度）

```
        Other
       $ 158k
            ╭─────────╮
  Startups  │ Tap for %│  Real Estate
   $ 75k    │ Allotted │   $ 390k
            │  $ 918k  │
   Bonds    ╰─────────╯
   $ 81k          Stocks
                  $ 213k
```

（参考图 1 样式 — 替换为时间数据）

- 中心大字：该范围总时长（如 `42h 18m`）
- 中心小字（顶）："Tap for %"（点击切换金额/百分比 → 时长/百分比）
- 中心副标题："Allotted"
- **环外悬浮 Tag 标签**：贴近对应弧段，自动避让
  - `Work  12h 30m`
  - `Personal  8h 15m`
  - `Health  3h 40m`
  - `Untagged  6h 02m`（灰色）

**Untagged 提示**：占比 > 30% 时，donut 中心追加 "Tag your time to see clearer patterns"

### 8.3 Chart / List 切换

- 位于 donut 下方左侧 `[ Chart | List ]` segment
- 右侧漏斗图标 → 打开 Filter 抽屉（§8.6）

#### Chart 模式
donut 下方留白；点击 Tag 段 → 进入 Tag 细分页（§8.5）

#### List 模式
donut 下方为 Tag 列表：
```
● Work               12h 30m   45%
● Personal            8h 15m   30%
● Health              3h 40m   13%
○ Untagged            6h 02m   12%
```
- Untagged 永远排最后
- 点击行 = 等同点击 donut 段

### 8.4 切换样式时

切到 List 时，donut 缩小到顶部仍可见，下方变列表（参考图 2 样式）。

### 8.5 Tag 细分页（Drill-down）

触发：点击 Tag 段或 List 行

布局（参考图 2 双 donut）：

```
┌──────────────────────────────────┐
│  ‹ Back          Stocks          │
├──────────────────────────────────┤
│         (主 Tag donut，高亮当前段) │
├──────────────────────────────────┤
│  [ Chart | List ]            ▽   │
├──────────────────────────────────┤
│       MSFT                        │
│      $ 21k    ╭─────────╮         │
│  AAPL         │  Stocks  │   GS   │
│  $ 22k        │  $ 213k  │  $ 93k │
│               ╰─────────╯         │
│       MC               SPY        │
│      $ 26k            $ 36k       │
│            TJX                    │
│           $ 16k                   │
└──────────────────────────────────┘
```

替换为时间维度：
- 顶部 = Tag 总 donut（其他 Tag 段变暗，当前 Tag 段高亮）
- 下方 = 该 Tag 内的 Task 子 donut + 环外悬浮 Task 标签
- 点击子 donut 的 Task 段 → 弹出**和 Home 一样的 Task 面板**（含 Recurring 的统计或 Once 的简短面板）

返回：左上 ‹ 或下滑手势。

### 8.6 Filter 抽屉（漏斗图标）

半屏 sheet：

```
┌─────────────────────────────┐
│  Filter                  ✕  │
├─────────────────────────────┤
│  Task Type                  │
│  ( All | Recurring | Task ) │  ← 默认 All
├─────────────────────────────┤
│  Tags                       │
│                             │
│  Displayed                  │
│    ● Work           ＝  －  │  ← 拖拽排序 / 点 - 隐藏
│    ● Personal       ＝  －  │
│    ● Health         ＝  －  │
│    ○ Untagged       ＝  －  │
│                             │
│  Hidden                     │
│    ● Sleep          ＝  ＋  │
│                             │
│  [ Reset ]                  │
└─────────────────────────────┘
```

- 抽屉关闭后，若过滤 ≠ 默认 → 漏斗图标右上角加小圆点提示"已过滤"
- 过滤只影响当前页面；不全局持久化（"Remember filter" 留作 Pro）

### 8.7 空状态

该范围无任何 Session：donut 灰色环，中心 `0h 0m` + 提示 "Start tracking to see your patterns"

---

## 九、Settings

从 Home / Allotted 右上角 ⚙ 进入。**iOS Grouped List 风格（默认方案，待参考图）**。

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
● Work          ＝  ›
● Personal      ＝  ›
● Health        ＝  ›
● Learning      ＝  ›
● Rest          ＝  ›
○ Untagged          ›       ← 系统标签，不可删 / 改色 / 重命名
```

- 拖拽 ＝ 排序（影响 Allotted 列表显示顺序）
- 点击行 → 进入 Tag 编辑页：
  - Name（文本）
  - Color（12 色调色盘网格，圆点选中态）
  - Default timer mode（Stopwatch / Countdown）
  - Default countdown duration（仅 Countdown 时）
  - Delete（红色按钮 + 确认 → 关联 Task 转入 Untagged）
- Untagged：仅可查看下属 Task 数量，无任何编辑入口

**12 色调色盘默认方案**（4×3 网格）：
红 / 橘 / 黄 / 浅绿 / 翠绿 / 青 / 蓝 / 靛 / 紫 / 粉 / 棕 / 灰
（具体色值见 §10.3 Tag 调色板）

**自定义色为 Pro**。

### 9.3 Notifications

| 项目 | 说明 |
|---|---|
| Task time reminder | 设了 startTime 的任务到点提醒 |
| Countdown end alert | "你设定 1h，是否继续？" |
| Weekly summary | 周日晚 19:00 推送本周（Phase 2） |
| Untracked time prompt | 当天有空白时段时提示补录（Phase 2） |

### 9.4 Pro / Upgrade

```
┌──────────────────────────────────┐
│ ⭐ Allot Pro                      │
│                                   │
│ Unlock advanced features          │
│                                   │
│ [Upgrade]                         │
└──────────────────────────────────┘
```

**Pro 功能（Phase 2 起逐步上线）**：
- Apple Health 集成（自动同步睡眠 → quickLog Sleep）
- 数据导出（CSV / JSON）
- 自定义 Tag 颜色
- 高级统计（趋势对比、年度回顾）
- 多设备 iCloud 同步
- Apple Watch 完整功能
- Magic Input（AI 自然语言新建任务）
- Filter 记忆 ("Remember filter")

**免费版**：无任务/Session 数量限制；完整 Home / Allotted / 计时 / 补录 / 基础提醒；Repeat 全部规则；深色模式。

### 9.5 Data & Privacy

- 全部数据本地存储
- 数据导出（Pro）
- 清除所有数据（带确认）
- 隐私政策链接

### 9.6 About

- 版本号
- 反馈 / 邮件
- 评分链接
- 致谢

---

## 十、统一交互组件

### 10.1 月历选择器（Date Picker）

参考样式：

```
┌──────────────────────────────────┐
│              ── (拖拽条)          │
│                                   │
│  Apr 2026          ‹ Today ›      │
│                                   │
│   S   M   T   W   T   F   S       │
│                   1   2   3   4   │
│   5   6   7   8   9  10  11       │
│  12  13  14  15  16  17  18       │
│ [19] 20  21  22  23  24  25       │  ← 今日红圆，选中实心
│  26  27  28  29  30               │
└──────────────────────────────────┘
```

**全 App 所有日期选择**统一使用：
- New Task 的 Date 选择
- Home 顶部点日期跳转
- 长期任务统计跳月份
- Settings → 数据导出范围

**交互**：
- ‹ › 翻月，Today 按钮回当月
- 点某天 → 选中并关闭
- 当月有记录的日期带小圆点标记（Home 跳转场景）

### 10.2 横向滑尺时间选择器

参考图 4 样式（黑底卡片 + 大字 + 底部红色游标 + 横向刻度）：

```
┌──────────────────────────────────┐
│                                   │
│              Start time           │
│                                   │
│              20:05                │  ← 大字
│                                   │
│  ─ ─ ─ ─ ─ │ ─ ─ ─ ─ ─ ─        │  ← 红色游标 + 刻度
│            ↑ 拖动改变             │
└──────────────────────────────────┘
```

**两种数据模式**：
- **Time of day**：刻度为 0:00 - 23:59，5 分钟一档（用于 startTime）
- **Duration**：刻度为 0 - 12h，5 分钟一档（用于 countdownDuration / quickLog 补录）

**交互**：
- 拖动滑尺 → 数字平滑变化
- 每 tick 一次轻震动（`UIImpactFeedbackGenerator .light`）
- 触底 / 触顶有强震反馈

**应用场景**：
- New Task → Add time / Duration
- Once 任务无记录 Complete → 弹补录
- 长按 Done → quickLog
- Stop 后 Edit duration

### 10.3 Tag 调色板

12 色固定预设（v1，自定义为 Pro）：

```
●红    ●橘    ●黄    ●浅绿
●翠绿  ●青    ●蓝    ●靛
●紫    ●粉    ●棕    ○灰(系统)
```

具体色值待确定（同时定义 Light / Dark 双模适配，Dark 模式饱和度降 10-15%）。

### 10.4 任务面板 Sheet

| Once Task | Recurring Task |
|---|---|
| 短面板（固定高度） | 滚动 sheet（默认 1/3 → 上滑至 2/3，封顶不全屏） |
| Complete / Edit / Remove | Edit / Remove + 多段统计 |
| 不可上拉 | 上拉到 2/3 后内部继续滚动 |

### 10.5 全局手势汇总

| 手势 | 触发 |
|---|---|
| 短按任务行 | 弹任务面板 |
| 长按任务行 | 直接开始计时 |
| 顶边下拉 | Timer 面板 |
| Timer 面板再下拉 | Focus 全屏 |
| 上拉 sheet | Recurring 面板 1/3 → 2/3 / 收 Timer 面板 |
| 横向滑动日期条 | 翻 7 天 |
| 横向滑动 Timer idle 时钟 | 切换 Stopwatch / 倒计时档位 |

---

## 十一、计时器引擎

### 11.1 状态机

```
idle → [Start] → running → [Pause] → paused → [Resume] → running
                    ↓                              ↓
                  [Stop]                         [Stop]
                    ↓                              ↓
                  ended (Session 保存到 SwiftData)
```

### 11.2 全局唯一

- 同一时刻只有一个 Session 可 running
- 已有 A 在跑，启动 B 时弹："Stop 'A' first?"

### 11.3 后台 / 锁屏

- 切走或锁屏：计时不停
- Live Activity / Dynamic Island 显示（Phase 2）

### 11.4 App 被杀恢复

- 开始 Session 时立即写 `{taskId, startAt}` 到 UserDefaults（App Group）
- 重开 App 检查：若 UserDefaults 有 activeSession 但 SwiftData 无对应 running → 弹窗：
  > "Your timer for '[Task]' was still running. Save with end time now?"
  > [Save] [Discard]

### 11.5 跨零点

- Stop 时若 startAt 在昨天、endAt 在今天 → 自动拆为两条 Session
- 特殊情况（App 被杀跨零点）：不拆，归到开始日期

### 11.6 时区

- startAt / endAt 存 UTC，显示用本地时区

---

## 十二、数据规则

| 规则 | 说明 |
|---|---|
| Session 重叠 | 不允许（quickLog 除外，不参与检测） |
| 跨日 Session | Stop 时自动拆分 |
| 时区存储 | UTC |
| 时间归属 | 按 startAt 本地时间归属 |
| 最小 Session 时长 | 无限制 |
| Quick Log 精度 | 5 分钟一档；默认值 = 该任务上次 quickLog 时长（首次 1h） |
| Tag 删除 | 不级联删 Task；关联 Task 转入 Untagged |
| Untagged | 系统标签，不可删 / 改色 / 重命名 |
| Task 删除 | 级联删 Session |
| 同时只能一个运行 Session | 全局唯一 |
| App 被杀恢复 | UserDefaults 哨兵 + 弹窗 |
| Done 状态 | 仅 Once Task 有；Recurring 无完成概念 |

---

## 十三、首次使用引导（Onboarding）

约 60-90 秒，4 步（**待参考图敲定，下面是默认方案**）：

**Step 1 — Welcome**
- 大标题 "Where did your time go?"
- 一句话定位 + Get started 按钮

**Step 2 — Pick your starter tags**
- "Pick the categories you'll use most"
- 默认勾选：☑ Work　☑ Personal　☐ Health　☐ Learning　☐ Rest
- `+ Add custom`（可现场加）
- `Skip` 也可（用户后期再补，所有 task 暂归 Untagged）

**Step 3 — Add your first task**
- 直接进入新建任务全屏页（默认 Task 模式）
- 输入框预填示例占位 "e.g. Write code"
- 完成后进入 Step 4

**Step 4 — Try the timer**
- 演示从顶部下拉手势（动效引导）
- "Pull down anytime to start a timer"
- Done → 进入 Home 主界面

---

## 十四、Design System

### 14.1 双主题 Color Tokens

App 支持 **System / Light / Dark** 三种 Appearance（System 跟随 iOS 设置）。所有界面同时设计两套色卡。

**语义色（待色值确定）**：

| Token | Light | Dark |
|---|---|---|
| bg/primary | 纯白 | 纯黑（OLED 优化） |
| bg/secondary | 浅灰 | 深灰 #1C1C1E |
| bg/elevated（sheet） | 白 + 阴影 | #2C2C2E + 半透明模糊 |
| text/primary | 深灰 #1C1C1E | 白 |
| text/secondary | 中灰 | 浅灰 |
| separator | 浅灰 | 深灰 |
| accent | 蓝 | 蓝（同色） |
| timer/bg | 黑 | 黑（一致） |
| timer/text | 白 | 白 |

**Tag 调色板**：Light 用饱和原色；Dark 自动降饱和 10-15% 避免刺眼。

**Liquid Glass 模糊**：Tab Bar、各种 sheet 在两种模式下都用半透明 + 背景模糊适配。

### 14.2 字体

- **正文**：SF Pro
- **数字（Timer / 时长 / startTime）**：SF Mono（等宽，避免跳动）
- **标题层级**：遵循 iOS HIG Title 1 / 2 / 3 / Body / Caption

### 14.3 圆角与间距

- 行高：56pt（任务行）/ 44pt（列表项）
- 按钮圆角：胶囊（高度 / 2）
- Sheet 圆角：顶部 16pt
- 卡片圆角：12pt

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
- Home 页（日期条 + 月历 + 任务行 + 排序 + 任务面板 + Hide/Show completed + FAB）
- 长按任务行 → 直接开始计时；短按 → 任务面板
- Task 类型：Once / Recurring
- Once 任务面板（短面板含 Complete / Edit / Remove + 无记录补录）
- Recurring 任务面板（垂直滚动 sheet 含统计 + dot calendar + share %）
- 新建任务全屏页（Tab 切换 + pill 行 + 横向滑尺时间选择器）
- 顶部 Timer 面板（纯数字 + 任务选择器 + 左右滑切档 + Focus 全屏）
- Stop 后轻量确认弹窗
- Quick Log（无记录 Complete + 长按 Done + 横向滑尺）
- 倒计时温和提醒模式
- 未绑定任务的计时
- Allotted 周视图（双 donut drill-down + 环外标签 + Filter 抽屉 + List/Chart 切换）
- Tag 系统（系统 Untagged + 12 色预设 + Settings → Tags 子页）
- 月历选择器（统一组件）
- 横向滑尺时间选择器（统一组件）
- Settings 全套（General / Tags / Notifications / Data / About）
- **深色模式**（System / Light / Dark）
- App 被杀恢复
- Onboarding（4 步）

### Phase 2

- Allotted 月/年视图
- Live Activity / Dynamic Island
- Widget
- Apple Watch
- 未记录提醒条
- 每周总结推送
- 数据导出（Pro）
- Apple Health 集成（Pro，自动同步睡眠）
- 自定义 Tag 颜色（Pro）
- 高级统计（Pro，趋势对比 / 年度回顾）
- **Magic Input**（Pro，AI 自然语言新建任务）
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
| 最低 iOS | 17+（SwiftData） |
| 最低 watchOS | 10+（Phase 2） |
| 数据存储 | SwiftData 本地 |
| 共享机制 | App Group |
| 计时精度 | 1 秒，存毫秒级时间戳 |
| 隐私 | 全部本地，不上服务器（Phase 1-2） |
| 隐私清单 | PrivacyInfo.xcprivacy |
| Haptic | UIImpactFeedbackGenerator（light / medium / heavy） |

---

## 十八、待办（参考图未到位的 TBD 项）

下列项目当前以默认方案写入，等参考图到位后再细化：

1. **Settings 主页风格** — 默认 iOS Grouped List；可能改为卡片或图标列表
2. **Tag 编辑页（Settings → Tag 单项）** — 默认色板 4×3 网格；具体布局待定
3. **Onboarding 4 步具体排版** — 默认方案，可能调整插画 / 动效
4. **Pull-down Timer 任务选择器** — 已基于 Timer 面板风格推断；可能优化分组
5. **Pro / Upgrade 页面**完整布局
6. **空状态插画**
7. **浅色模式**色卡微调（当前以反推为主，需真图校准）
8. **Tag 调色板 12 色具体色值**（Light / Dark 双套）
