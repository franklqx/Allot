# Allot — Design System v0.2

> 配套文档：`PRODUCT_DOC_v2.md`
> 设计气质：**克制、极简、每日陪伴感**。参考产品：Robinhood（2024 rebrand）、Origin、Apple 原生。
> 反面参考：暖色牛皮纸感（v0.1 方向已废弃）、金融工具感、彩虹数据可视化、渐变堆砌。

---

## 1. 设计哲学

### 1.1 一句话定调
**"系统底色 + 一抹数据色"**——App chrome 完全用苹果系统中性色，彩色只留给数据本身（长方体、色方块）。

### 1.2 三条不可让步的原则
1. **克制 over 热闹**：chrome 不上色。按钮黑白两色，文字黑白两色，背景纯白/纯黑。彩色只在数据可视化里出现。
2. **排序 over 分类**：看数据优先看"谁最长"，不是"谁属于哪类"。Task 颜色按时长排名动态分配（Robinhood 式）。
3. **不评判 over 激励**：不给绿好红坏，不给"完成率"，不给推送焦虑。只呈现事实。

### 1.3 视觉关键词
`restrained · monochrome chrome · data as color · daily calm · Apple native · Robinhood minimal`

### 1.4 反模式（Don't）
- ❌ 暖色底（米色纸、牛皮黄）——已废弃的 v0.1 方向
- ❌ 品牌 accent 色渗透 chrome（不用 Robin Neon / Coral / iOS System Blue）
- ❌ 渐变（Liquid Glass 系统原生例外）
- ❌ 彩色图标、彩色 tab bar
- ❌ 数据可视化用纯彩虹（红橙黄绿青蓝紫堆一起）
- ❌ "今日完成 100% 🟢"式评判色块
- ❌ Emoji 装饰、表情堆砌
- ❌ 任何红色出现在非删除场景（日历不染红）

---

## 2. 颜色系统

> 命名：`role/variant`
> 所有色都给 Light + Dark 两套值
> **App chrome 用中性色**，**数据可视化用独立 12 色调色板**，两者严格分离

### 2.1 中性色 Neutrals（App chrome）

| Token | Light | Dark | 用途 |
|---|---|---|---|
| `bg/primary` | `#FFFFFF` | `#000000` | 主背景（纯白 / 纯黑 OLED） |
| `bg/secondary` | `#F2F2F7` | `#1C1C1E` | 卡片/分组背景（iOS systemGray6） |
| `bg/elevated` | `#FFFFFF` | `#2C2C2E` | Sheet、modal（iOS systemGray5） |
| `bg/glass` | 系统原生 `.regularMaterial` | 系统原生 `.regularMaterial` | Tab Bar 玻璃 |
| `text/primary` | `#000000` | `#FFFFFF` | 主文字（iOS label） |
| `text/secondary` | `#3C3C4399` | `#EBEBF599` | 次级文字（iOS secondaryLabel，60% alpha） |
| `text/tertiary` | `#3C3C434D` | `#EBEBF54D` | 占位、disabled（iOS tertiaryLabel，30% alpha） |
| `separator` | `#3C3C431F` | `#54545899` | 分隔线（iOS separator） |
| `border/subtle` | `#0000001A` | `#FFFFFF1F` | 卡片描边（可选） |

**说明**
- 全部对齐 **Apple HIG 系统色**，Dynamic Color 自动适配 Light/Dark
- 主背景是**纯白 / 纯黑**（不是 v0.1 的米白 `#FBF7F1`）
- 文字层次用 alpha 阶梯（iOS 标准），不用色相变化
- **没有 accent 色**——主按钮黑底白字，不染系统蓝

### 2.2 按钮 & 交互态

| 状态 | Light | Dark |
|---|---|---|
| Primary button bg | `#000000` | `#FFFFFF` |
| Primary button text | `#FFFFFF` | `#000000` |
| Secondary button bg | `#F2F2F7` | `#1C1C1E` |
| Secondary button text | `#000000` | `#FFFFFF` |
| Ghost button text | `#000000` | `#FFFFFF` |
| Selected state bg | `#000000` + 10% alpha 底 | `#FFFFFF` + 10% alpha 底 |
| Pressed state | scale 0.97 + opacity 0.85 | 同 |

> 注意：计时中状态**不染色**，只用大字号 + 粗度差凸显。没有彩色进度环。

### 2.3 数据可视化 12 色（Data Palette）

> **只用于 Allotted 页的长方体和 Task/Tag 色方块**。不渗透 chrome。
> 灵感来自 Robinhood Portfolio Strategies 的多色持仓图：低饱和、柔和、区分度高。

| # | 名 | Hex | 用途 |
|---|---|---|---|
| 1 | Sky | `#5BB2E8` | **Work** · By Task 排名 1 |
| 2 | Amber | `#F89C58` | By Task 排名 2 |
| 3 | Rose | `#EFB0C0` | **Hobby** · By Task 排名 3 |
| 4 | Lilac | `#B084F5` | **Learn** · By Task 排名 4 |
| 5 | Lime | `#A8C66C` | **Health** · By Task 排名 5 |
| 6 | Marigold | `#F5B950` | **Life** |
| 7 | Teal | `#7DB6B0` | **Leisure** |
| 8 | Coral | `#E3472C` | 扩展用 |
| 9 | Plum | `#5F2C82` | 扩展用 |
| 10 | Mustard | `#D9B64A` | 扩展用 |
| 11 | Sage | `#8FB089` | 扩展用 |
| 12 | Gray | `#8A8F96` | **Untagged / Others（合并段）** |

**调色思路**
- 没有纯红、纯蓝、纯绿——饱和度中低，色相柔
- 并列呈现在一条长方体 bar 上时像 Robinhood Strategies 截图，不像彩虹
- **Tag 色固定映射**（Work=Sky, Health=Lime...）
- **Task 色按时长动态排名**分配（前 5 用 Sky/Amber/Rose/Lilac/Lime，其余合并成 Gray 的 "Others"）
- Untagged 和 Others 共用 Gray `#8A8F96`（永远不同框出现，不冲突）

**Dark 模式微调**
- 所有色饱和度降 8-12%，亮度提 5-10%，避免刺眼
- 色号通过 Asset Catalog 的 Any/Dark 两套值管理

### 2.4 状态色 State

| Token | Light | Dark | 用途 |
|---|---|---|---|
| `state/success` | `#34C759` | `#30D158` | 完成态 ✓（克制使用，iOS systemGreen） |
| `state/destructive` | `#FF3B30` | `#FF453A` | 删除按钮（iOS systemRed，**仅此处**用红） |
| `state/warning` | `#FF9500` | `#FF9F0A` | 时间冲突（iOS systemOrange） |

> 规则：红色**只在 Delete 按钮上**出现，日历不染红、数字不染红。

### 2.5 计时器专属色 Focus Tab

| Token | Light | Dark | 用途 |
|---|---|---|---|
| `focus/bg` | `#FFFFFF` | `#000000` | Focus 页背景（与主背景一致） |
| `focus/digit` | `#000000` | `#FFFFFF` | 大字数字（不染色） |
| `focus/digit-running` | `#000000` | `#FFFFFF` | 计时中 = 粗体 + 呼吸动画（不改色） |
| `focus/track` | `#00000008` | `#FFFFFF1F` | 底部时间刻度背景 |

---

## 3. Typography

### 3.1 字族
- **正文/UI**：SF Pro Text（≤19pt）/ SF Pro Display（≥20pt）
- **数字（计时器、时长、百分比、startTime）**：SF Mono
- 不引入第三方字体

### 3.2 字号阶梯

| Token | Size | Weight | 用途 |
|---|---|---|---|
| `display/focus` | 88pt | 300 (Light) | Focus 页大数字（SF Mono） |
| `display/xl` | 48pt | 400 (Regular) | Allotted 总时长（SF Mono） |
| `display/lg` | 34pt | 600 | 百分比主数（如 `23.24%`） |
| `title/lg` | 28pt | 600 (Semibold) | Page Title |
| `title/md` | 22pt | 600 | Sheet Title、Section Header |
| `title/sm` | 17pt | 600 | Task Row 主标题 |
| `body/lg` | 17pt | 400 | 标准正文 |
| `body/md` | 15pt | 400 | 次级正文 |
| `body/sm` | 13pt | 400 | Caption、Tag chip 文字 |
| `caption/sm` | 11pt | 500 | Footnote、时间戳 |
| `mono/lg` | 22pt | 400 | 列表时长（SF Mono） |
| `mono/md` | 15pt | 400 | 小号统计数字（SF Mono） |

### 3.3 字重原则
- 默认 400 Regular
- 强调用 600 Semibold——**不用 700 Bold**
- Focus 页大数字用 300 Light（呼吸感）
- 永远不用 Italic

### 3.4 Dynamic Type
- 全部 `Font.system(.body)` 等语义字号
- 支持 XS → AX5
- Focus 数字 + 统计数字封顶 +2 档

---

## 4. 间距与尺寸

### 4.1 4pt 基础栅格

| Token | Value |
|---|---|
| `space/2xs` | 4pt |
| `space/xs` | 8pt |
| `space/sm` | 12pt |
| `space/md` | 16pt（默认） |
| `space/lg` | 24pt |
| `space/xl` | 32pt |
| `space/2xl` | 48pt |
| `space/3xl` | 64pt |

**常用**
- 卡片内边距：`16`
- Section 间距：`24`
- Page 左右边距：`20`
- Task Row 上下：`14`

### 4.2 圆角

| Token | Value | 用途 |
|---|---|---|
| `radius/xs` | 6pt | 小色方块、小按钮 |
| `radius/sm` | 10pt | 输入框、Pill |
| `radius/md` | 14pt | 卡片、Task Row |
| `radius/lg` | 20pt | Bottom Sheet 顶部 |
| `radius/xl` | 28pt | Modal、大卡片 |
| `radius/full` | 9999pt | 圆形按钮、胶囊 |

**长方体专用**
- 3D 等距长方体**无圆角**（硬边线框更利落，参考 Robinhood Strategies）
- 顶面/侧面用 1pt 浅线描出透视（见 §5.4）

### 4.3 触摸目标
- 最小 44×44pt
- Task Row ≥ 56pt
- Tab Bar 图标命中 ≥ 48pt
- 长方体命中区 ≥ 44pt（窄小段用透明 overlay 扩大）

---

## 5. 组件 Components

### 5.1 Task Row（首页核心）

```
┌──────────────────────────────────────┐
│  ○  Write code                20:05  │
└──────────────────────────────────────┘
```

| 元素 | 规格 |
|---|---|
| 高度 | 56pt |
| 左侧图标 | 24×24pt SF Symbol（见 §6.3），**不染色** |
| 主标题 | `title/sm`，`text/primary` |
| 右侧 startTime | `mono/md`，`text/tertiary` |
| 完成态 | 主标题颜色 → `text/tertiary`（不加删除线） |
| 进行中态 | 整行左侧出现 2pt 竖线 `text/primary` + 右端数字跳动（不染色） |
| 长按态 | 整行 scale 0.98 + haptic medium，800ms 后开始计时 |

> 不显示分隔线。不显示 Tag（Tag 只在 Task 面板里）。

### 5.2 Pill（New Task 字段选择器）

```
┌─────────┐ ┌──────────┐ ┌─────────┐
│ #Work   │ │ Stopwatch│ │ + Tag   │
└─────────┘ └──────────┘ └─────────┘
```

| 状态 | 背景 | 文字 |
|---|---|---|
| Default | `bg/secondary` | `text/secondary` |
| Selected | `text/primary`（黑/白反） | `bg/primary` |
| With Tag | Tag 色（见 §2.3）alpha 20% | `text/primary` |

- 高度 32pt
- 圆角 `radius/sm`（10pt）

### 5.3 Bottom Sheet

| 类型 | 默认高度 | 最大高度 | 行为 |
|---|---|---|---|
| Once Task Panel | 内容自适应（~30%） | 固定 | 点外部关闭 |
| Recurring Task Panel | 33% | 67% | 可上拉，不全屏 |
| Quick Log Slider | ~25% | 固定 | 仅 ✓ 关闭 |
| Filter Menu | ~40% | 固定 | 点外部关闭 |

- 顶部圆角 `radius/lg`（20pt）
- Grabber 4pt 高、36pt 宽，`text/tertiary`
- 背景 `bg/elevated`
- 后方 dim `rgba(0,0,0,0.32)`（Light）/ `rgba(0,0,0,0.5)`（Dark）

### 5.4 Prism Chart（Allotted 页核心）

**取代了 v0.1 的 Donut。** 横排 3D 等距长方体，宽度 = 时长占比，高度固定。

```
默认态（未选中）:
┌─────────────────┬──────────┬───┬──┐
│      Work       │  Health  │Ⅰ│▫│
└─────────────────┴──────────┴───┴──┘
 Sky (47%)         Lime (26%) ...

选中态（点 Work）:
                  ╭──────────╮ ╭─╮ ╭╮
┌─────────────────╮│ ░░░░░░░░ │ │░│ │░│
│      Work       ││ ░░ hollow│ │░│ │░│
└─────────────────╯╰──────────╯ ╰─╯ ╰╯
   solid, 居中保持     其他退让，空心线框
```

| 元素 | 规格 |
|---|---|
| 高度 | 64pt（等距 3D 视觉厚度 ~12pt） |
| 宽度 | 按占比 = `(duration / total) × 可用宽度`，最小 16pt |
| 顶面/侧面 | 1pt 白线（Light）/ 浅灰线（Dark）勾透视 |
| 填充色 | Tag 色（By Tag）或 Task 排名色（By Task，见 §2.3） |
| 圆角 | 无（硬边） |
| 段间隔 | 2pt 透明 gap |
| 选中态 | 保持实心 + 原位不动；其他段**填充 → 透明**，保留 1pt 线框，左右退让 4pt 留间隙 |
| 未选中态切换 | 250ms ease-in-out 过渡 |
| 空数据 | 一个浅灰描边空盒 + "No data in this range" |

**点击行为**
- **By Tag 模式**：点 → 下方列表滚动到该 tag 的详细任务；长方体本身保持选中动画
- **By Task 模式**：点 → 弹出 Task 面板（沿用 Home 的 Once/Recurring 面板）
- 点 Others（Gray 段）→ 弹出列表 sheet 展示被合并的所有 task

### 5.5 Prism Chart 下方列表

参考 Robinhood Portfolio 列表样式：

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

| 元素 | 规格 |
|---|---|
| 行高 | 48pt |
| 左侧色方块 | 14×14pt `radius/xs`，对应 Tag/Task 色 |
| 主名 | `body/lg`，`text/primary` |
| 时长 | `mono/md`，右对齐，`text/secondary` |
| 百分比 | `mono/md`，右对齐，`text/primary` |
| 右箭头 | `chevron.right` 12pt，`text/tertiary` |
| Untagged / Others | 无右箭头（不可 drill） |
| 分隔线 | `separator` 1px，不全宽（左右各 16pt 内缩） |

### 5.6 Dot Calendar（Recurring Panel 用）

> 二元，不显示强度。

```
M  T  W  T  F  S  S
●  ●  ○  ●  ●  ○  ●
●  ○  ●  ●  ●  ●  ●
```

| 元素 | 规格 |
|---|---|
| 圆点 | 10×10pt |
| 间距 | 14pt（横/纵） |
| 已完成 | Tag 色实心 |
| 未完成 | `separator` 空心 1pt |
| 未来 | 不渲染 |
| 今天 | 外圈 +1pt 描边，`text/primary` 色（**不染红**） |

### 5.7 Horizontal Slider（时长/时间选择器）

```
        ┌─────┐
   30   │ 45  │  60
   ─────┼─────┼─────
        ▲
```

| 元素 | 规格 |
|---|---|
| 刻度高 | 24pt |
| 主刻度间隔 | 5min / 15min / 60min |
| 当前值 | 中央 `title/md` SF Mono |
| 游标 | `text/primary` 色 2pt 竖线（**不染红**，v0.1 的红色游标已废弃） |
| Haptic | 每 5min 一次 light tick |

### 5.8 Calendar Picker

- 标准 iOS `.graphical` DatePicker
- `.tint(.primary)` 覆盖系统默认蓝
- 今天外圈 `text/primary` 描边（**不红点**）
- 周末文字色 `text/secondary`（不染红）
- 选中日：黑底白字胶囊（Light）/ 白底黑字胶囊（Dark）

### 5.9 底部导航（Liquid Glass Tab Bar）

```
顶部右上角：⚙ Settings

底部：
┌─────────────────────────────────────┐
│  [ Home  Focus  Allotted ]    [ + ] │
│   ↑ 左侧胶囊（3 tabs）         ↑ FAB
└─────────────────────────────────────┘
```

| 元素 | 规格 |
|---|---|
| 左侧胶囊 | iOS 26 原生 Liquid Glass TabView |
| Tab 数 | 3（Home / Focus / Allotted，左→右） |
| Tab 图标 | SF Symbols 22pt，filled = 选中 |
| 选中色 | `.tint(.primary)`——选中态图标变黑/白（跟随主题） |
| 未选中色 | 系统默认（Liquid Glass 自动适配） |
| Tab 文字 | 不显示 |
| 右侧 `+` FAB | 独立按钮，`TabView` 外层 overlay，`bg/primary` 圆 + 1pt 描边 + `plus` 图标；**看今天**=`+`新建；**看其他日期**=`Today` 文字回今天 |
| Settings | 右上角 `gearshape`，不在底部 |

**Tab 定义**
1. Home — `house` / `house.fill`
2. Focus — `timer` / `timer.circle.fill`
3. Allotted — `chart.bar.xaxis` / `chart.bar.xaxis.fill`（长方体 bar 图标，不是 pie）

### 5.10 Buttons

| 类型 | Light bg | Light text | Dark bg | Dark text | 用途 |
|---|---|---|---|---|---|
| Primary | `#000000` | `#FFFFFF` | `#FFFFFF` | `#000000` | Save、Start、Add |
| Secondary | `#F2F2F7` | `#000000` | `#1C1C1E` | `#FFFFFF` | Cancel、次级 |
| Ghost | 透明 | `#000000` | 透明 | `#FFFFFF` | Nav "Done" |
| Destructive | 透明 | `#FF3B30` | 透明 | `#FF453A` | Delete |
| Icon | 透明 | `text/secondary` | 透明 | `text/secondary` | Nav 图标 |

- 圆角 `radius/sm`（10pt）或 `radius/full`（胶囊）
- 高度 44pt / 36pt（紧凑）
- Pressed：scale 0.97 + opacity 0.85

---

## 6. 图标

### 6.1 SF Symbols 优先
- SF Symbols 5+
- Weight `.regular` / `.semibold`
- 不用 multicolor / hierarchical / palette

### 6.2 常用 Symbol 清单

| 用途 | Symbol |
|---|---|
| Tab: Home | `house` / `house.fill` |
| Tab: Focus | `timer` / `timer.circle.fill` |
| Tab: Allotted | `chart.bar.xaxis` / `chart.bar.xaxis.fill` |
| FAB `+` / Today | `plus` / 文字 |
| Settings | `gearshape` |
| 计时模式 | `stopwatch` |
| 倒计时 | `hourglass` |
| Recurring 任务图标 | `circle.dashed` |
| Once 任务图标 | `square` / `checkmark.square.fill` |
| 完成 | `checkmark` |
| 编辑 | `pencil` |
| 删除 | `trash` |
| Tag | `tag` |
| 日历 | `calendar` |
| 筛选 | `line.3.horizontal.decrease.circle` |
| View 切换 | `rectangle.3.group` |
| 关闭 sheet | `xmark` |
| 返回 | `chevron.left` |
| 行内 disclosure | `chevron.right` |

---

## 7. 动效与触觉

### 7.1 动画时长

| Token | Duration | Curve | 用途 |
|---|---|---|---|
| `motion/instant` | 100ms | easeOut | toggle |
| `motion/quick` | 200ms | easeInOut | 按钮 pressed |
| `motion/standard` | 250ms | easeInOut | Sheet、Prism 选中切换 |
| `motion/expressive` | 450ms | spring(0.55, 0.82) | 计时启动、Focus 入场 |

### 7.2 Haptics

| 场景 | Type |
|---|---|
| 点击按钮 | `.selection` |
| 长按开始计时 | `.impact(.medium)` |
| 完成任务 | `.notification(.success)` |
| 删除 | `.notification(.warning)` |
| Slider 经过整点 | `.impact(.light)` |
| Prism 选中 | `.impact(.soft)` |
| Filter 展开 | `.selection` |

### 7.3 Reduced Motion
- Spring → linear，时长减半
- Prism 选中过渡跳过，直接终态
- Focus 入场不缩放

---

## 8. 无障碍

### 8.1 对比度
- 正文 WCAG AA 4.5:1
- 大号文字 3:1
- Prism 色块与背景 ≥ 3:1（所有 12 色均已校验）

### 8.2 Dynamic Type
- 支持 XS → AX5
- AX 档位：Tab 图标 28pt；Task Row 自适应；双行 meta 自动折行

### 8.3 VoiceOver

| 元素 | Label 模板 |
|---|---|
| Task Row | "{title}, {accumDuration}, starts at {startTime}" |
| 进行中 Task | "Currently running, {title}, {elapsed} elapsed" |
| Prism | "{name}, {duration}, {percent}% of total" |
| Prism (Others) | "Others, {n} tasks combined, {duration}, {percent}%" |
| Dot Calendar | "{date}, {completed/notCompleted}" |
| Focus 主屏 | "Stopwatch, {currentTime}, double tap to pause" |

### 8.4 其它
- 交互 hit area ≥ 44×44pt
- 颜色不是唯一信息载体（完成态有 ✓；Prism 选中态有线框 + 位移）
- 支持 Bold Text、Increase Contrast
- 锁竖屏（iPad 后续）

---

## 9. Light vs Dark 适配

1. **纯白 / 纯黑**：bg/primary 就是 `#FFFFFF` / `#000000`（不折中）
2. **12 色 Dark 版降饱和**：色号通过 Asset Catalog Any/Dark 自动切换
3. **没有 accent 提亮逻辑**（因为 App 没有 accent）
4. **阴影**：Light `rgba(0,0,0,0.06)`，Dark `rgba(0,0,0,0.4)`
5. **跟随系统切换**：默认 Auto，Settings → Appearance 可强制

---

## 10. 资源规格

### 10.1 App Icon
- 1024×1024 主图
- 设计方向：**白底 + 一个极简 3D 立方体线框**（待设计，与 Prism Chart 视觉呼应）
- 不放文字、不渐变
- Dark variant：黑底 + 同图形

### 10.2 Launch Screen
- 纯 `bg/primary`
- 中央极小 logomark（待设计）
- 无 spinner

### 10.3 插画
- Onboarding 4 步：极简线条（待设计）
- 空状态：文案 + 图标，不画插画

---

## 11. 设计原则 Checklist

每次做新 UI 前：

- [ ] chrome 上有没有彩色？（应该没有）
- [ ] 数据以外的地方有没有 accent 色？（应该没有）
- [ ] 红色是不是只出现在 Delete 按钮上？
- [ ] 字重最重到 600 了吗？
- [ ] 留白够吗？
- [ ] 有没有评判用户？（无红绿对比、无"完成率"）
- [ ] Dark mode 试过了吗？
- [ ] Dynamic Type AX3 撑得开吗？
- [ ] VoiceOver 念得通吗？
- [ ] Reduced Motion 下还能用吗？
- [ ] 删掉这个元素功能还成立吗？（成立就删）

---

## 12. TBD

- App Icon 最终方案（白底 3D 立方体方向）
- Onboarding 4 张插画
- Prism Chart 的动效曲线最终微调（在真机上试）
- Watch App 配色（可能只用 top 4 色）
- Widget 三种尺寸具体布局
- Live Activity compact / expanded 视觉
- Pro 升级页视觉（暂缓）

---

## Appendix A — 颜色样本

```
中性色（Light）
bg/primary       ████  #FFFFFF   纯白
bg/secondary     ████  #F2F2F7   iOS Gray 6
bg/elevated      ████  #FFFFFF
text/primary     ████  #000000   纯黑
text/secondary   ████  rgba(60,60,67,0.6)
text/tertiary    ████  rgba(60,60,67,0.3)

中性色（Dark）
bg/primary       ████  #000000   纯黑 OLED
bg/secondary     ████  #1C1C1E   iOS Gray 6 dark
bg/elevated      ████  #2C2C2E
text/primary     ████  #FFFFFF
text/secondary   ████  rgba(235,235,245,0.6)

数据 12 色（Light base）
1  Sky          ████  #5BB2E8    Work / Rank 1
2  Amber        ████  #F89C58    Rank 2
3  Rose         ████  #EFB0C0    Hobby / Rank 3
4  Lilac        ████  #B084F5    Learn / Rank 4
5  Lime         ████  #A8C66C    Health / Rank 5
6  Marigold     ████  #F5B950    Life
7  Teal         ████  #7DB6B0    Leisure
8  Coral        ████  #E3472C    extended
9  Plum         ████  #5F2C82    extended
10 Mustard      ████  #D9B64A    extended
11 Sage         ████  #8FB089    extended
12 Gray         ████  #8A8F96    Untagged / Others
```

---

**v0.2 | 2026-04-22 | 全面重写（基于 Robinhood / Origin / Apple 原生 方向）**
