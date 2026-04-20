# Allot — Design System v0.1

> 配套文档：`PRODUCT_DOC_v2.md`
> 设计气质：温暖、安静、像一本牛皮纸笔记本。参考产品：Reflect、Stoic、Bear、Streaks。
> 反面参考：Things 3 / Linear（过冷、过几何、太"软件感"）。

---

## 1. 设计哲学

### 1.1 一句话定调
**"像一张被太阳晒过的纸"** —— 暖、柔、低饱和、有呼吸。绝不冷光、绝不工业、绝不"开发者审美"。

### 1.2 三条不可让步的原则
1. **温暖 over 精确**：颜色偏暖（带一点黄／红的灰），而不是中性灰或冷蓝灰。
2. **留白 over 信息密度**：宁可少一行、字大一号，也不要塞满屏。
3. **不评判 over 激励**：圆点日历不显示强度，统计数字不染色（绿好红坏 = ❌），只呈现事实。

### 1.3 视觉关键词
`warm · paper · soft contrast · generous spacing · serene · grown-up`

### 1.4 反模式（Don't）
- ❌ 冷蓝、霓虹、纯黑纯白
- ❌ 渐变（除 Liquid Glass 外）、毛玻璃滥用
- ❌ 强阴影（material design 那种 elevation）
- ❌ 任务图标（不做 Wake up ☀️ / Wind down 🌙 这类）
- ❌ 数字大色块染色（"今日完成 100% 🟢"这种）
- ❌ Emoji 表情堆砌

---

## 2. 颜色系统（Color Tokens）

> 命名约定：`role/variant`，例如 `bg/primary`、`text/secondary`。
> 所有颜色都给 Light + Dark 两套值。
> Tag 调色板独立于 UI 中性色，单独成章。

### 2.1 中性色 Neutrals

| Token | Light (HEX) | Dark (HEX) | 用途 |
|---|---|---|---|
| `bg/primary` | `#FBF7F1` | `#161412` | 主背景（米白纸 / 深咖啡夜） |
| `bg/secondary` | `#F4EFE6` | `#1F1C18` | 卡片/分组背景 |
| `bg/elevated` | `#FFFFFF` | `#26221D` | 浮起 sheet、modal |
| `bg/glass` | `rgba(251,247,241,0.72)` + blur(24) | `rgba(22,20,18,0.72)` + blur(24) | Liquid Glass Tab Bar |
| `text/primary` | `#1C1814` | `#F2EDE4` | 主文字、标题 |
| `text/secondary` | `#6B6359` | `#A89E91` | 次级文字、说明 |
| `text/tertiary` | `#A39A8C` | `#6B6359` | 占位、disabled、辅助标签 |
| `separator` | `rgba(28,24,20,0.06)` | `rgba(242,237,228,0.08)` | 分隔线（极淡） |
| `border/subtle` | `rgba(28,24,20,0.10)` | `rgba(242,237,228,0.12)` | 卡片描边（可选，慎用） |

**说明**
- 主背景 `#FBF7F1` 是带一点黄的米色，比纯白少 4% 亮度——长时间看不刺眼。
- 深色模式不是 `#000`，是 `#161412`（暖深咖），夜间观感更柔。
- 几乎不用边框，用背景色阶差代替。

### 2.2 Accent Color（强调色）

> **Accent 是什么**：贯穿全 App 的一个"高亮色"，只用在关键交互/状态上：当前进行中的计时器、主按钮（Save、Start）、选中态、Tab Bar 当前页图标、Tag 默认色之一。
> 用得克制，用户的注意力立刻知道"这是重要的"。
> Allot 的 accent = **珊瑚红 Coral**（暖、有活力但不刺眼，与米色背景天然搭配）。

| Token | Light | Dark | 用途 |
|---|---|---|---|
| `accent/primary` | `#E5544A` | `#FF6B5C` | 主按钮、计时中数字、当前 Tab 图标 |
| `accent/soft` | `#FCE8E4` | `#3A201C` | 主按钮 pressed 背景、选中行底色 |
| `accent/text-on-accent` | `#FFFFFF` | `#1C1814` | 在 accent 色块上的文字 |

### 2.3 Tag 调色板（12 色）

> 12 个手选的暖色，覆盖红橙黄绿青蓝紫粉棕灰。
> 每个 Tag 有 3 个值：`base`（圆点/小色块）、`soft`（chip 背景）、`text`（chip 文字）。
> 深色模式下 base 略提亮、soft 大幅压暗。
> Untagged 永远用 `stone`，且不可被用户改名/删除。

| # | 名称 | Base (Light) | Soft (Light) | Base (Dark) | 气质 |
|---|---|---|---|---|---|
| 1 | Coral | `#E5544A` | `#FCE8E4` | `#FF6B5C` | 工作/重要 |
| 2 | Marigold | `#E08A3C` | `#FBEBD7` | `#F2A05A` | 创造/能量 |
| 3 | Mustard | `#C9A227` | `#F5ECCB` | `#E0B843` | 学习/思考 |
| 4 | Sage | `#7A9272` | `#E4ECDF` | `#9DB494` | 健康/平静 |
| 5 | Olive | `#6F7A3D` | `#E5E8D2` | `#94A05A` | 自然/户外 |
| 6 | Teal | `#3E8079` | `#D8E8E5` | `#5FA39B` | 专注/深度 |
| 7 | Powder | `#7896A8` | `#DEE7EC` | `#9AB5C5` | 阅读/反思 |
| 8 | Periwinkle | `#7C7BB0` | `#E2E1EE` | `#9D9CCB` | 创作/写作 |
| 9 | Mauve | `#A574A0` | `#ECDFEA` | `#C194BC` | 社交/关系 |
| 10 | Terracotta | `#B0593F` | `#F0DCD4` | `#CC7A60` | 运动/身体 |
| 11 | Rose | `#C76A7A` | `#F4DFE3` | `#E08A99` | 休闲/自我 |
| 12 | Stone (Untagged) | `#9C928A` | `#ECE7E0` | `#B0A89E` | 未分类（系统 Tag） |

**调色思路**
- 没有纯红、纯蓝、纯绿——所有色都拉了一点棕调，互相之间不会"打架"。
- 同时呈现在一个 Donut 图上时，整体看起来像一张老地图，不像彩虹。
- 用户在 Tag 编辑页只能从这 12 个里选——不开放自定义 HEX，避免审美崩坏。

### 2.4 状态色 State

| Token | Light | Dark | 用途 |
|---|---|---|---|
| `state/success` | `#6F8F5C` | `#8FAF7C` | 完成态 ✓（克制使用） |
| `state/warning` | `#C9853D` | `#E0A05A` | 时间冲突提示 |
| `state/destructive` | `#B84A3E` | `#D66A5C` | 删除按钮 |

> 注意：完成态的"绿"是橄榄绿，不是 system green。任务列表里完成的 row 不染色，只是文字变 `text/tertiary` + 一个细 ✓。

### 2.5 计时器专属色 Timer

| Token | Light | Dark | 用途 |
|---|---|---|---|
| `timer/running` | `#E5544A`（=accent） | `#FF6B5C` | 计时中数字、进度环 |
| `timer/paused` | `#A39A8C` | `#6B6359` | 暂停态 |
| `timer/track` | `rgba(28,24,20,0.06)` | `rgba(242,237,228,0.08)` | 进度环底色 |

---

## 3. Typography

### 3.1 字族
- **正文/UI**：SF Pro Text（≤19pt）／SF Pro Display（≥20pt）— 系统默认，跟随 Dynamic Type
- **数字（计时器、统计）**：SF Mono — 等宽，避免数字跳动
- **不引入第三方字体**（不用 Inter、不用衬线）

### 3.2 字号阶梯（基于 iOS 标准 + Allot 微调）

| Token | Size | Weight | Line Height | Tracking | 用途 |
|---|---|---|---|---|---|
| `display/timer` | 72pt | 200 (Ultralight) | 1.0 | -2 | 计时器主屏数字（SF Mono） |
| `display/xl` | 48pt | 300 (Light) | 1.1 | -1 | Allotted 总时长大数字（SF Mono） |
| `title/lg` | 28pt | 600 (Semibold) | 1.2 | -0.4 | Page Title（如 "Today"） |
| `title/md` | 22pt | 600 | 1.25 | -0.3 | Sheet Title、Section Header |
| `title/sm` | 17pt | 600 | 1.3 | -0.2 | Task Row 主标题 |
| `body/lg` | 17pt | 400 | 1.4 | -0.4 | 标准正文 |
| `body/md` | 15pt | 400 | 1.4 | -0.3 | 次级正文、说明文字 |
| `body/sm` | 13pt | 400 | 1.35 | -0.1 | Caption、Tag chip 文字 |
| `caption/sm` | 11pt | 500 | 1.3 | 0 | Footnote、时间戳 |
| `mono/lg` | 22pt | 400 | 1.0 | 0 | 列表里的累计时长（SF Mono） |
| `mono/md` | 15pt | 400 | 1.0 | 0 | 小号统计数字（SF Mono） |

### 3.3 字重原则
- 默认 400（Regular）
- 强调用 600（Semibold）— **不用 Bold/700**，太重显得廉价
- 计时器数字用 200/300，"轻盈感"是 Allot 的标志
- 永远不用 Italic

### 3.4 Dynamic Type
- 全部使用 `Font.system(.body)` 等语义字号，不写死 pt
- 支持 XS → AX5 全 12 档
- 计时器数字 + 统计数字：跟随 Dynamic Type 但封顶 +2 档（避免巨大数字撑破 layout）

---

## 4. 间距与尺寸

### 4.1 4pt 基础栅格
所有 padding/margin/gap 必须是 4 的倍数。

| Token | Value |
|---|---|
| `space/2xs` | 4pt |
| `space/xs` | 8pt |
| `space/sm` | 12pt |
| `space/md` | 16pt（**默认**） |
| `space/lg` | 24pt |
| `space/xl` | 32pt |
| `space/2xl` | 48pt |
| `space/3xl` | 64pt |

**常用组合**
- 卡片内边距：`16` 四周
- Section 间距：`24`
- Page 左右边距：`20`（不是 16，给一点更舒展的感觉）
- Task Row 上下：`14`

### 4.2 圆角

| Token | Value | 用途 |
|---|---|---|
| `radius/xs` | 6pt | Tag chip、小按钮 |
| `radius/sm` | 10pt | 输入框、Pill |
| `radius/md` | 14pt | 卡片、Task Row |
| `radius/lg` | 20pt | Bottom Sheet 顶部 |
| `radius/xl` | 28pt | Modal、大卡片 |
| `radius/full` | 9999pt | 圆形按钮、头像 |

### 4.3 触摸目标
- 最小 44×44pt（HIG 标准）
- Task Row 总高 ≥ 56pt
- Tab Bar 图标命中区 ≥ 48pt

---

## 5. 组件 Components

### 5.1 Task Row（首页核心组件）

```
┌──────────────────────────────────────┐
│  ●  Read 30 pages                    │
│     #Reading · 📖 0:25 / 0:30       │
│                              07:30  │
└──────────────────────────────────────┘
```

| 元素 | 规格 |
|---|---|
| 高度 | 56pt（含 padding） |
| 左侧色点 | 8×8pt 圆，使用 Tag base 色 |
| 主标题 | `title/sm`，`text/primary` |
| Meta 行 | `body/sm`，`text/secondary`，包含 Tag chip + 累计时长（SF Mono） |
| 右侧 startTime | `mono/md`，`text/tertiary` |
| 完成态 | 主标题颜色 → `text/tertiary`，无删除线 |
| 进行中态 | 整行背景 → `accent/soft`，色点变成跳动的 dot |
| 长按态 | 整行 scale 0.98 + haptic medium，800ms 后开始计时 |

### 5.2 Pill（New Task 页字段选择器）

```
┌─────────┐ ┌──────────┐ ┌─────────┐
│ #Work   │ │ Stopwatch│ │ + Tag   │
└─────────┘ └──────────┘ └─────────┘
```

| 状态 | 背景 | 文字 |
|---|---|---|
| Default | `bg/secondary` | `text/secondary` |
| Selected | `accent/soft` | `accent/primary` |
| With Tag | Tag 的 `soft` 色 | Tag 的 `text` 色 |

- 高度 32pt
- 圆角 `radius/sm`（10pt）
- 横向滚动时不出现 scrollbar

### 5.3 Bottom Sheet

| 类型 | 默认高度 | 最大高度 | 行为 |
|---|---|---|---|
| Once Task Panel | 内容自适应（约 30%） | 固定不可拉 | 点击外部关闭 |
| Recurring Task Panel | 33% (1/3) | 67% (2/3) | 可上拉，**不全屏** |
| Quick Log Slider | 内容自适应（约 25%） | 固定 | 仅 ✓ 关闭 |
| Filter Drawer | 50% | 80% | 可上拉 |

- 顶部圆角 `radius/lg`（20pt）
- 顶部 4pt 高的 grabber，居中，颜色 `text/tertiary`，宽 36pt
- 背景 `bg/elevated`
- 后方背景 dim：`rgba(0,0,0,0.32)`（Light）／`rgba(0,0,0,0.5)`（Dark）

### 5.4 Donut Chart（Allotted 页）

| 元素 | 规格 |
|---|---|
| 外环厚度 | 24pt |
| 内环厚度 | 16pt（drill-down 双环模式时） |
| 中心数字 | `display/xl` 总时长（SF Mono） |
| 中心副标题 | `body/sm` "this week" |
| 段间隔 | 2pt 透明 gap |
| 选中段 | 厚度 +4pt，其它段 opacity 0.5 |
| 颜色 | 各 Tag 的 `base` 色 |

### 5.5 Dot Calendar（Recurring Panel 用）

> **二元，不显示强度**——只有"做了"和"没做"，避免评判。

```
M  T  W  T  F  S  S
●  ●  ○  ●  ●  ○  ●
●  ○  ●  ●  ●  ●  ●
```

| 元素 | 规格 |
|---|---|
| 圆点尺寸 | 10×10pt |
| 圆点间距 | 14pt（横）／14pt（纵） |
| 已完成 | 该 Task 的 Tag base 色，实心 |
| 未完成 | `separator` 色，空心圆环 1pt |
| 未来日期 | 不渲染 |
| 今天 | 外圈 +1pt 描边，accent 色 |

### 5.6 Horizontal Slider（时长选择器）

> 用在 New Task 时长输入、Quick Log popup。

```
        ┌─────┐
   30   │ 45  │  60
   ─────┼─────┼─────
        ▲
```

| 元素 | 规格 |
|---|---|
| 刻度高 | 24pt |
| 主刻度间隔 | 5min（短）/ 15min（中）/ 60min（长） |
| 当前值 | 中央 `title/md`（SF Mono） |
| 滑动 haptic | 每 5min 一次 light tick |
| 单位标签 | 下方 `body/sm` "min" / "hr" |

### 5.7 Calendar Picker（开始日期选择）

- 标准 iOS DatePicker（`.graphical` 风格）
- 主色覆盖为 `accent/primary`
- 周末文字色 `text/secondary`（不染红）

### 5.8 Tab Bar（Liquid Glass）

| 元素 | 规格 |
|---|---|
| 背景 | `bg/glass`（毛玻璃 + 72% 不透明） |
| 高度 | 49pt + safe area |
| 图标 | SF Symbols，22pt |
| 当前页 | `accent/primary`，图标 filled 变体 |
| 非当前 | `text/tertiary`，图标 regular 变体 |
| 标题 | 不显示文字（只有图标） |

四个 Tab：
1. Home — `house`
2. Timer — `timer`
3. Allotted — `chart.pie`
4. Settings — `gearshape`

### 5.9 Buttons

| 类型 | 背景 | 文字 | 用途 |
|---|---|---|---|
| Primary | `accent/primary` | `accent/text-on-accent` | Save、Start Timer |
| Secondary | `bg/secondary` | `text/primary` | Cancel、次级操作 |
| Ghost | 透明 | `accent/primary` | 顶部 nav 的 "Done" |
| Destructive | 透明 | `state/destructive` | Delete |
| Icon | 透明 | `text/secondary` | nav bar 图标按钮 |

- 全部圆角 `radius/sm`
- 高度 44pt（标准）／ 36pt（紧凑，sheet 内）
- pressed 态：scale 0.97 + 背景加深 8%

---

## 6. 图标 Iconography

### 6.1 SF Symbols 优先
- 全 App 使用 SF Symbols 5+
- Weight：`.regular`（默认）／ `.semibold`（强调）
- 不使用 multicolor / hierarchical / palette 变体（保持单色克制）

### 6.2 自定义图标
- **不为 Task 制作图标**（不做 Wake up ☀️ / Wind down 🌙）
- App 图标、Onboarding 插画 — 待设计阶段

### 6.3 常用 Symbol 清单

| 用途 | Symbol |
|---|---|
| Tab: Home | `house` / `house.fill` |
| Tab: Timer | `timer` |
| Tab: Allotted | `chart.pie` / `chart.pie.fill` |
| Tab: Settings | `gearshape` / `gearshape.fill` |
| 计时模式 | `stopwatch` |
| 倒计时模式 | `hourglass` |
| 完成 | `checkmark` |
| 编辑 | `pencil` |
| 删除 | `trash` |
| 添加 | `plus` |
| Tag | `tag` |
| 日历 | `calendar` |
| 筛选 | `line.3.horizontal.decrease` |
| 关闭 sheet | `xmark` |
| 返回 | `chevron.left` |

---

## 7. 动效与触觉

### 7.1 动画时长

| Token | Duration | Curve | 用途 |
|---|---|---|---|
| `motion/instant` | 100ms | easeOut | 状态切换（如 toggle） |
| `motion/quick` | 200ms | easeInOut | 按钮 pressed、selected |
| `motion/standard` | 300ms | easeInOut | Sheet 出现/消失、页面过渡 |
| `motion/expressive` | 500ms | spring(0.5, 0.8) | 计时器启动、完成庆祝 |

### 7.2 Haptics

| 场景 | Type |
|---|---|
| 点击按钮 | `.selection` |
| 长按开始计时 | `.impact(.medium)` |
| 完成任务 | `.notification(.success)` |
| 删除任务 | `.notification(.warning)` |
| Slider 经过整点 | `.impact(.light)` |
| Pull-to-pick task（Timer 页） | `.impact(.soft)` |

### 7.3 Reduced Motion
- 用户开启 Reduce Motion 时：所有 spring 改为 linear，duration 减半
- Donut 图入场动画跳过，直接显示终态

---

## 8. 无障碍 Accessibility

### 8.1 对比度
- 全部正文文字达到 WCAG AA（4.5:1）
- 大号文字（≥17pt 600）达到 3:1
- Tag base 色与 bg/primary 至少 3:1（可识别色块）

### 8.2 Dynamic Type
- 支持 XS → AX5
- AX 档位下：
  - Tab Bar 图标增大到 28pt
  - Task Row 高度自适应内容（不固定 56pt）
  - 双行 Meta 自动折行

### 8.3 VoiceOver 标签

| 元素 | Label 模板 |
|---|---|
| Task Row | "{title}, tag {tagName}, {accumDuration} of {goalDuration}, starts at {startTime}" |
| 进行中 Task | "Currently running, {title}, {elapsed} elapsed" |
| Donut 段 | "{tagName}, {duration}, {percent}% of total" |
| Dot Calendar 圆点 | "{date}, {completed/notCompleted}" |
| 计时器主屏 | "Stopwatch, {currentTime}, double tap to pause" |

### 8.4 其它
- 所有交互元素 hit area ≥ 44×44pt
- 颜色不是唯一信息载体（完成态有 ✓，不只是变灰）
- 支持 Bold Text、Increase Contrast
- 支持横屏？— **不支持**，iPhone 锁竖屏；iPad 后续考虑

---

## 9. Light vs Dark 适配规则

1. **不是简单反色**：暗色背景用 `#161412`（暖深咖），不用 `#000`
2. **Tag soft 色在暗色下大幅压暗**：避免亮 chip 在暗背景上"漂浮"
3. **Accent 在暗色下提亮**：`#E5544A` → `#FF6B5C`，保证可见性
4. **阴影**：Light 用 `rgba(0,0,0,0.06)`，Dark 用 `rgba(0,0,0,0.4)`（暗色下阴影更深）
5. **图片/截图区**：暗色下加 1pt `border/subtle` 描边，避免与背景混淆
6. **跟随系统切换**：默认 Auto，可在 Settings → Appearance 强制 Light/Dark

---

## 10. 资源规格 Asset Specs

### 10.1 App Icon
- 1024×1024 主图，自动缩放各尺寸
- 设计方向：**米色背景 + 一个简单的几何形状（待设计）**
- 不放文字、不放渐变
- Dark variant：深咖背景 + 同形状

### 10.2 Launch Screen
- 纯 `bg/primary` 背景
- 中央放一个极小的 logomark（待设计）
- 不放 loading spinner

### 10.3 插画
- Onboarding 4 步：每步一张极简线条插画（待设计）
- 风格参考：Reflect 的 onboarding（细线、单色、不超过 3 个元素）
- 空状态：不画插画，用一行温柔的文案 + 一个图标

---

## 11. 设计原则 Checklist

每次做新 UI 前问自己：

- [ ] 用了暖色还是冷色？（必须暖）
- [ ] 留白够吗？（不够就再加 8pt）
- [ ] 字重最重到 600 了吗？（不要 Bold）
- [ ] Accent 用得克制吗？（一屏 ≤ 2 处）
- [ ] 有没有"评判"用户？（没有红绿对比、没有"!"、没有"only X% done"）
- [ ] Dark mode 试过了吗？
- [ ] Dynamic Type AX3 撑得开吗？
- [ ] VoiceOver 念得通吗？
- [ ] Reduced Motion 下还能用吗？
- [ ] 删掉这个元素，功能还成立吗？（如果成立，删）

---

## 12. TBD（待定）

- App Icon 最终方案
- Onboarding 4 张插画
- Watch App 配色（需简化，可能只用 4 个 Tag 色）
- Widget 三种尺寸的具体布局
- Live Activity 的 compact / expanded 状态视觉
- 强制 Light/Dark 切换的过渡动效
- Pro 升级页的视觉（暂缓）

---

## Appendix A — 颜色样本（ASCII 预览）

```
中性色（Light）
bg/primary       ████  #FBF7F1   米白纸
bg/secondary     ████  #F4EFE6   浅米
bg/elevated      ████  #FFFFFF   纯白浮起
text/primary     ████  #1C1814   暖黑
text/secondary   ████  #6B6359   暖灰
text/tertiary    ████  #A39A8C   浅暖灰

中性色（Dark）
bg/primary       ████  #161412   暖深咖
bg/secondary     ████  #1F1C18
bg/elevated      ████  #26221D
text/primary     ████  #F2EDE4   米白
text/secondary   ████  #A89E91

Accent
accent/primary   ████  #E5544A   珊瑚红（Light）
accent/primary   ████  #FF6B5C   亮珊瑚（Dark）
accent/soft      ████  #FCE8E4   珊瑚雾（Light）

Tag 12 色（Light base）
1  Coral        ████  #E5544A
2  Marigold     ████  #E08A3C
3  Mustard      ████  #C9A227
4  Sage         ████  #7A9272
5  Olive        ████  #6F7A3D
6  Teal         ████  #3E8079
7  Powder       ████  #7896A8
8  Periwinkle   ████  #7C7BB0
9  Mauve        ████  #A574A0
10 Terracotta   ████  #B0593F
11 Rose         ████  #C76A7A
12 Stone        ████  #9C928A   (Untagged)
```

---

**v0.1 | 2026-04-19 | 待用户审阅**
