# Allotted Prism — Design Spec

> 本文件专门定义 Allotted 页面的 **Prism**（等距彩色横棱柱）组件。几何、状态、动效、边界情况都集中在这里；代码落地前必须先锁这份 spec。

---

## 0. References（参考素材）

> 使用前请扫一遍这些链接。调研结论见各条下的 **Takeaway**。

### 0.1 Robinhood Strategies — 主参考 ✅

> **顶部参考图即 Robinhood Strategies app 内的 allocation 视图**（官方 support 文档未收录该组件，仅在 app 内可见）。所有几何 / 配色 / 状态规则以这张图为基准 source of truth。

- [Robinhood Strategies charts (官方支持页，仅含饼图/折线图版本)](https://robinhood.com/us/en/support/articles/strategies-charts/)
- [Robinhood UI 简洁性分析 — Jeffrey Zhong / Medium](https://medium.com/@jeffrey_zhong_35871/robinhoods-simple-user-interface-76a2ee7cd6e)

**Takeaway**：参考图核心视觉特征（以此为准绳）：
- 横躺等距棱柱，投影角约 **15–20°**（浅等距，非经典 30°）
- 三面可见：顶面 + 正面 + **仅最后一段**露出右端盖（整体是单实体切片，非独立积木叠放）
- 段间用 **白色细线**分隔（约 1–1.5 px）
- 粉彩配色（柔和蓝 / 橙 / 粉 / 紫），扁平填色，**无渐变 / 无投影**
- 所有段共享同一截面（高度 / 深度一致），只长度不同

### 0.2 等距柱状图（通用视觉语言）
- [Isometric Bar Chart — Figma Community](https://www.figma.com/community/file/1208766312782389424/isometric-bar-chart)
- [How to Animate an Isometric Bar Chart in After Effects — Lesterbanks](https://lesterbanks.com/2020/08/how-to-easily-animate-an-isometric-bar-chart-in-ae/)
- [Iconscout "isometric bar chart" icon set](https://iconscout.com/icons/chart-stacked-bar)

**Takeaway**：等距柱状图的标准投影角是 **30° / 30°**（经典 isometric），或 **15°–20°** 伪等距（用户参考图属于后者，顶面更扁，视觉更"纸片感"）。三面可见（顶 + 前 + 右端），白色描边隔段是常见模式。

### 0.3 SwiftUI 原生 3D 图（iOS 26+）
- [WWDC25: Bring Swift Charts to the third dimension](https://developer.apple.com/videos/play/wwdc2025/313/)
- [Chart3D — Apple Developer Documentation](https://developer.apple.com/documentation/charts/chart3d)
- [Cook up 3D charts with Swift Charts — Artem Novichkov](https://artemnovichkov.com/blog/cook-up-3d-charts-with-swift-charts)
- [WWDC 2025 – Swift Charts 3D 完整指南 — dev.to](https://dev.to/arshtechpro/wwdc-2025-swift-charts-3d-a-complete-guide-to-3d-data-visualization-40nc)

**Takeaway**：`Chart3D` + `RectangleMark(x, y, z)` + `chart3DCameraProjection(.orthographic)` 理论上能渲染等距棱柱。**代价**：
1. 仅 iOS 26+，Allot 目前 deployment target 需确认
2. 自定义描边/圆角/状态（hollow 等）受限，Chart3D 更像 SceneKit 封装
3. 动效（段宽平滑过渡、点击高亮）需绕过框架默认行为

**结论倾向**：用 `Chart3D` 做 Prism 得不偿失，自绘 `Path` + `CGAffineTransform` 更自由。详见 §6 技术选型。

### 0.4 Rive / Lottie（动效参考）
- [Rive & Lottie Isometric chart animation — LottieFolder](https://lottiefolder.com/animation/isometric-chart-rive/)
- [Beautiful, Dynamic Charts in Rive — Viget](https://www.viget.com/articles/beautiful-dynamic-charts-in-rive)
- [Bar graph animate on — Rive Community](https://rive.app/marketplace/5606-11009-bar-graph-animate-on/)
- [Isometric chart on the screen — LottieFiles](https://lottiefiles.com/21322-isometric-chart-on-the-screen)
- [Isometric bar graph Glowing — LottieFiles](https://lottiefiles.com/122110-isometric-bar-graph-glowing)
- [Isometric Lottie Animation – Powerful Tool (Dribbble)](https://dribbble.com/shots/19231131-Isometric-Lottie-Animation-Powerful-Tool)

**Takeaway**：
- **Rive 不适合我们**：Viget 的文章明确说 Rive 每个数据点都要手动打关键帧，"works best with small data points"，而 Allot 的 tag 数量可变。
- **Lottie 同理**：预渲染的 JSON，无法响应动态 allotted 数组。
- **动效思路应自绘**：SwiftUI `withAnimation` + `animatableData` 插值段宽，比 Rive/Lottie 更贴合数据驱动场景。
- 但这些参考的**缓动节奏**（通常 0.6–0.9s，easeInOut 或 spring 弹动）值得借鉴。

### 0.5 SwiftUI 自绘等距 shape（手写范例）
- [Isometric Animation using Shape & AnimatablePair — YouTube](https://www.youtube.com/watch?v=hR4g6rgQBio)

**Takeaway**：用 `Shape` + `AnimatablePair` 驱动顶点插值是 SwiftUI 画可动 isometric 几何的标准模式，后面 §6 会基于这个思路写代码。

---

## 1. 几何（Geometry） — TBD

（下一步填写：投影角度、顶/正/端三面构造、像素级坐标系）

## 2. 尺寸规则（Sizing）— TBD

（按 allotted 时长按比例分段，最小可见宽度，间距，整体画布尺寸）

## 3. 颜色分配（Color）— TBD

（段配色逻辑：继承 Tag.color？固定调色板？对比度规则）

## 4. 交互状态（States）— TBD

- Default（全彩）
- Hover / Pressed
- Selected（高亮 + 其他段 hollow）
- Empty（无 allotted 时的占位）

## 5. 动效（Motion）— TBD

- 进入动画
- 段宽变化过渡
- 选中/取消选中切换
- 点击反馈

## 6. 技术选型与实现骨架（Implementation）— TBD

- 方案 A：`Shape` + `Path` 自绘（推荐）
- 方案 B：`Chart3D`（iOS 26 限制）
- 坐标变换 / AnimatablePair 写法

## 7. 边界情况（Edge Cases）— TBD

- 单段 / 零段 / 超多段
- allotted 总时长很小（全部压到最小宽）
- 动态改名/改色时的过渡

---

_Last updated: 2026-04-23 — 仅 §0 References 已填；§1–§7 待起草。_
