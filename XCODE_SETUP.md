# Xcode 手动配置详细步骤

代码部分全部写完了。Xcode UI 那部分**只能你来做**——文本编辑没法可靠地操作 Capability、新 target 创建、provisioning profile 关联。这份文档把每一步具体到点哪个按钮、填什么字段、看到什么算成功。

预计耗时 **25-30 分钟**。一次做完，不要分阶段。

---

## 0. 准备

### 0.1 打开项目

```
open /Users/frankli/Desktop/关羽与吕布/Allot/Allot/Allot.xcodeproj
```

### 0.2 确认登录状态

`Xcode → Settings → Accounts`（顶栏菜单 / `⌘,`）

确认列表里有你的 Apple ID，右下角 Team 列表里能看到 `526LTP6Z7D`（项目里写死的 team ID）。

如果没有，点 `+` → Apple ID → 登录。

### 0.3 关闭模拟器和真机预览

避免 build 跑起来干扰下面的 capability 编辑。

---

## 1. 主 target 加 4 个 Capability（10 分钟）

### 1.1 选中主 target

左侧 Project Navigator 顶部点 **Allot**（蓝色图标，最顶上的），中间 editor 出现 target 列表 → 选 **Allot**（不是 AllotTests / AllotUITests / AllotLiveActivityExtension）。

### 1.2 切到 "Signing & Capabilities" tab

editor 顶上有几个 tab：General / Signing & Capabilities / Resource Tags / Info / Build Settings / ...

点 **Signing & Capabilities**。

确认下面这些字段：
- **Automatically manage signing** ✅ 勾着
- **Team**: 你的 team（526LTP6Z7D）
- **Bundle Identifier**: `com.EL.fire.Allot1`
- **Provisioning Profile**: Xcode Managed Profile（自动）

### 1.3 加 Capability #1: Sign in with Apple

点 **+ Capability**（左上角，有时候叫 "+ Capability" 有时候叫 `+`）。弹出搜索框。

搜索框输入 `sign` → 双击 **Sign in with Apple**。

加完后 capabilities 列表里出现一行：
```
▾ Sign in with Apple
```
没什么要配的，下一项。

### 1.4 加 Capability #2: iCloud（最容易出错）

再次点 **+ Capability** → 搜 `icloud` → 双击 **iCloud**。

下面的配置**严格按这个填**：

- **Services**：勾 ✅ **CloudKit**（**只勾这一个**，不要勾 Key-value storage 和 iCloud Documents）
- **Containers** 区域：你会看到一个空的列表 + 下方 `+`/`-` 按钮和一个刷新箭头
  - 点 `+`
  - 在弹出的对话框输入：`iCloud.com.EL.fire.Allot1`
    - ⚠️ **必须完全一致**——大小写、点号、`iCloud.` 前缀都不能错
    - 这个 container ID 已经写死在 [AllotApp.swift](Allot/Allot/AllotApp.swift) 第 24 行的 `cloudKitDatabase: .private("iCloud.com.EL.fire.Allot1")`，和 [Allot.entitlements](Allot/Allot/Allot.entitlements) 里
  - 点 OK / Add

加完后 Containers 列表里出现：
```
☑ iCloud.com.EL.fire.Allot1
```
**前面的复选框必须勾上**。

> ⚠️ 如果点 `+` 之后报 **"Failed to register iCloud container"**：
> 1. 打开浏览器去 https://developer.apple.com/account/resources/identifiers/list/cloudContainer
> 2. 用同一个 Apple ID 登录
> 3. 点右上 `+` → CloudKit Container → Description: "Allot Production" / ID: `iCloud.com.EL.fire.Allot1` → Continue → Register
> 4. 回 Xcode，点 Containers 旁边的 🔄 刷新按钮
> 5. 容器就出现可勾选了

### 1.5 加 Capability #3: App Groups

**+ Capability** → 搜 `app group` → 双击 **App Groups**。

配置：
- 点 Containers 列表下方的 `+`
- 输入：`group.com.EL.fire.Allot1`
  - ⚠️ 必须**完全一致**，写死在 [WidgetSnapshot.swift:12](Allot/Allot/Engine/WidgetSnapshot.swift)
- 点 OK
- 列表里勾 ☑ `group.com.EL.fire.Allot1`

> ⚠️ 同上，注册失败的话去 https://developer.apple.com/account/resources/identifiers/list/applicationGroup 手动注册一次再回 Xcode 刷新。

### 1.6 加 Capability #4: Background Modes

**+ Capability** → 搜 `background` → 双击 **Background Modes**。

下方出现一组复选框，**只勾这一个**：
- ☑ **Remote notifications**

其他的（Audio, Location updates, ...）**不要勾**。

### 1.7 验证 entitlements 文件没被覆盖

主 editor 切到 **Build Settings** tab → 搜索框 `entitlements` → 找到 **Code Signing Entitlements**。

应该是：`Allot/Allot.entitlements`（Debug 和 Release 两行都是这个）。

如果 Xcode 自动改成了别的路径（比如 `Allot.entitlements`），手动改回 `Allot/Allot.entitlements`。

打开 [Allot/Allot/Allot.entitlements](Allot/Allot/Allot.entitlements) 文件确认内容包含：
- `com.apple.developer.applesignin` → `Default`
- `com.apple.developer.icloud-container-identifiers` → `iCloud.com.EL.fire.Allot1`
- `com.apple.developer.icloud-services` → `CloudKit`
- `com.apple.security.application-groups` → `group.com.EL.fire.Allot1`
- `aps-environment` → `development`

如果这些 key 不全（Xcode 重新生成可能丢失），把文件用我写的那份覆盖回去。

### 1.8 第一次 build 试一下

`⌘B`（Product → Build）

如果只对主 target build，应该 succeed。

**常见错误**：

- `Provisioning profile doesn't include the com.apple.developer.icloud-services entitlement`
  → Capability 没加成功。回 1.4 重做。
- `App Group ID is invalid`
  → 1.5 的 ID 拼写错了。
- `Could not find Apple Developer account`
  → 0.2 没登录。

如果 build 通过，✅ Step 1 完成。

---

## 2. 新建 Widget Extension Target（10 分钟）

### 2.1 触发新 target 向导

顶栏菜单 **File → New → Target...**（或 `⌘⇧N` 然后选 Target）。

### 2.2 选模板

弹出窗口顶部搜索框输入 `widget` → 选 **Widget Extension**（图标是一个紫色方块） → 点 **Next**。

⚠️ 注意：
- 不要选 "Live Activity"——你已经有一个了
- 不要选 "App Intent Extension"
- 就选 **Widget Extension**

### 2.3 填写 target 信息

按这个填：

| 字段 | 值 |
|---|---|
| **Product Name** | `AllotWidget` |
| **Team** | 你的 team（同主 app）|
| **Organization Identifier** | 自动填，应该是 `com.EL.fire.Allot1`（如果不是，手动改成这个）|
| **Bundle Identifier** | 应该自动变成 `com.EL.fire.Allot1.AllotWidget` |
| **Language** | Swift |
| **Include Live Activity** | ❌ **不勾**（已经有了） |
| **Include Configuration App Intent** | ❌ **不勾**（用我们自己的 StartTaskIntent） |
| **Project** | Allot |
| **Embed in Application** | Allot |

点 **Finish**。

### 2.4 处理 "Activate scheme?" 弹窗

Xcode 弹一个 "Activate AllotWidget scheme?" 对话框。点 **Activate**。

### 2.5 看现状

左侧 Project Navigator 现在多了一个 `AllotWidget` 文件夹，里面有 Xcode 自动生成的几个文件，**类似**：

```
AllotWidget/
├── AllotWidget.swift              ← 模板生成的 widget
├── AllotWidgetBundle.swift        ← 模板生成的 bundle
├── AllotWidgetControl.swift       ← 模板生成的 Control
├── AppIntent.swift                ← 模板生成的 intent
├── Assets.xcassets
└── Info.plist
```

具体哪几个文件视 Xcode 版本而异。

### 2.6 删掉模板 .swift 文件

我已经写好了完整的 widget 代码在 `Allot/AllotWidget/` 文件夹。要把模板生成的 `.swift` 全部删掉，换成我写的。

**逐个右键模板文件 → Delete**：
- `AllotWidget.swift` → 右键 → Delete → 弹窗选 **Move to Trash**
- `AllotWidgetBundle.swift` → 同上
- `AllotWidgetControl.swift`（如果有）→ 同上
- `AppIntent.swift`（如果有）→ 同上

⚠️ **保留 `Assets.xcassets` 和 `Info.plist`**——别删。

### 2.7 把我写的 widget 文件加进 target

我已经在磁盘上的 `Allot/AllotWidget/` 文件夹里放了 9 个文件：

```
Allot/AllotWidget/
├── AllotWidgetBundle.swift
├── SnapshotProvider.swift
├── LiveFocusWidget.swift
├── TodayAllottedWidget.swift
├── TodayCircularWidget.swift
├── FocusInlineWidget.swift
├── QuickStartWidget.swift
├── Info.plist                  ← 我写的，覆盖 Xcode 模板的
└── AllotWidget.entitlements    ← 我写的，新加
```

**用 Finder 拖入**：

1. Finder 打开 `/Users/frankli/Desktop/关羽与吕布/Allot/Allot/AllotWidget/`
2. 在 Xcode 左侧 Project Navigator 找到 `AllotWidget` 文件夹（顶层蓝色文件夹图标，不是同名 target）
3. **同时全选** Finder 里的 7 个 `.swift` 文件 + `AllotWidget.entitlements`（不包括 Info.plist——下一步处理）
4. 拖到 Xcode 的 `AllotWidget` 文件夹里
5. **弹出对话框很重要**：
   - **Destination**: ✅ Copy items if needed（**不勾**——文件已经在那个目录，不需要再拷贝；勾了会重复）
   - **Added folders**: 选 **Create groups**
   - **Add to targets**: ✅ **AllotWidget**（勾）/ ❌ Allot（**不勾**——这些是 widget 专属代码）
6. 点 **Finish**

### 2.8 替换模板的 Info.plist

Xcode 模板生成的 `Info.plist` 内容大同小异，但安全起见用我的覆盖：

1. Finder 复制 `Allot/AllotWidget/Info.plist`
2. Xcode 里左键点模板生成的 `Info.plist` → 右键 → **Show in Finder**
3. 替换那个文件
4. 回 Xcode 自动 reload

或者直接在 Xcode 里打开模板的 Info.plist，把内容改成我写的那份（很短，就 NSExtension 一段）。

### 2.9 验证文件加进 target 了

左侧选中 `LiveFocusWidget.swift` → 右侧 File Inspector（`⌘⌥1` 切到 Inspector，再点 File 那一栏）→ **Target Membership** 区域：

- ✅ **AllotWidget**（勾着）
- ❌ Allot（不勾）
- ❌ AllotLiveActivityExtension（不勾）

如果不对，点旁边的勾选框调整。

对其他 6 个新加的 .swift 文件做同样检查。

---

## 3. 配置 AllotWidget Target（10 分钟）

### 3.1 选中 AllotWidget target

Project Navigator 顶上 **Allot**（蓝色项目图标）→ editor 中间 target 列表选 **AllotWidget**。

### 3.2 Signing & Capabilities

切到 **Signing & Capabilities** tab。

- **Team**: 同主 app
- **Bundle Identifier**: `com.EL.fire.Allot1.AllotWidget`
- **Automatically manage signing** ✅

### 3.3 加 App Groups capability

**+ Capability** → 搜 `app group` → 双击 **App Groups**。

Containers 区域：
- 点 `+`
- 输入：`group.com.EL.fire.Allot1`
  - ⚠️ **必须和主 app 完全一致**——这就是数据通道，对不上 widget 看不到任何数据
- 列表里勾 ☑ `group.com.EL.fire.Allot1`

⚠️ **这一步不要加 Sign in with Apple、iCloud、Background Modes**——widget 不需要。只加 App Groups。

### 3.4 验证 entitlements 文件

切到 **Build Settings** → 搜 `entitlements` → 找 **Code Signing Entitlements** 行。

值应该是：`AllotWidget/AllotWidget.entitlements`（不是 Allot/Allot.entitlements）。

如果 Xcode 自动生成了一个空的 `AllotWidgetExtension.entitlements`，改成 `AllotWidget/AllotWidget.entitlements`（指向我写的那份）。

打开 [Allot/AllotWidget/AllotWidget.entitlements](Allot/AllotWidget/AllotWidget.entitlements) 确认有：
- `com.apple.security.application-groups` → `group.com.EL.fire.Allot1`

只这一项就够了，**不要**加 iCloud / SIWA / Background。

### 3.5 把主 app 的共享文件加到 widget target

Widget 进程跑的时候需要主 app 里这 4 个文件——Xcode 不会自动给，要手动加。

**操作**（每个文件做一次）：

打开主 app 那个文件 → 右侧 **File Inspector**（`⌘⌥1` 切到 Inspector，点 File 栏）→ **Target Membership** 区域 → 勾 ✅ **AllotWidget**。

要加的 4 个文件：

| 文件路径 | 为什么需要 |
|---|---|
| [Allot/Engine/WidgetSnapshot.swift](Allot/Allot/Engine/WidgetSnapshot.swift) | Widget 通过这个类型解码 App Group 数据 |
| [Allot/Views/Components/DesignTokens.swift](Allot/Allot/Views/Components/DesignTokens.swift) | `Color.tagColor()` + `formatDurationCompact` 等 |
| [Allot/Views/Components/PrismMiniView.swift](Allot/Allot/Views/Components/PrismMiniView.swift) | TodayAllottedWidget 渲染砖块用 |
| [Allot/AppIntents/StartTaskIntent.swift](Allot/Allot/AppIntents/StartTaskIntent.swift) | QuickStartWidget 启动 task 的 App Intent |

**操作示例（拿 WidgetSnapshot.swift 举例）**：

1. Project Navigator 展开 `Allot` 文件夹 → `Engine` → 点 `WidgetSnapshot.swift`
2. 右侧 Inspector 切到 File（`⌘⌥1`）
3. 找到 **Target Membership** 区域，看到列表：
   - ☑ Allot
   - ☐ AllotTests
   - ☐ AllotUITests
   - ☐ AllotLiveActivityExtension
   - ☐ AllotWidget   ← **勾这个**
4. 主 app 那个 ☑ Allot 保持勾着，新加 ☑ AllotWidget

对另外 3 个文件做同样的事。

### 3.6 参考 LiveActivity 的做法（可选验证）

要确认你做对了，可以看现有 LiveActivity 是怎么共享文件的：

Project Navigator 找 `Allot/Activities/FocusActivityAttributes.swift` → File Inspector → Target Membership 应该是：
- ☑ Allot
- ☑ AllotLiveActivityExtension

同样的模式我们要应用到 4 个 widget 共享文件上：
- ☑ Allot
- ☑ AllotWidget

DesignTokens.swift 已经被 LiveActivity 共享过：
- ☑ Allot
- ☑ AllotLiveActivityExtension
- ☑ AllotWidget   ← 你要新加这个

### 3.7 验证编译

**选 AllotWidget scheme** → 顶上 Run target 选 **AllotWidget** → `⌘B` build。

应该 build succeed。

**常见错误**：

- `Cannot find 'WidgetSnapshot' in scope`
  → 3.5 没加 `WidgetSnapshot.swift` 到 AllotWidget target
- `Cannot find 'Color.tagColor' in scope`
  → 3.5 没加 `DesignTokens.swift` 到 AllotWidget target
- `Cannot find 'PrismMiniView' in scope`
  → 3.5 没加 `PrismMiniView.swift` 到 AllotWidget target
- `Cannot find 'StartTaskIntent' in scope`
  → 3.5 没加 `StartTaskIntent.swift` 到 AllotWidget target
- `App group entitlement not allowed`
  → 3.3 没加 App Groups capability，或者 ID 拼错了

### 3.8 切回 Allot scheme

顶上 Run target 切回 **Allot**（不然 `⌘R` 会跑 widget extension 而不是主 app）。

---

## 4. 第一次完整 Run + 验收

### 4.1 模拟器或真机？

**强烈建议先真机**——Sign in with Apple 在 simulator 上经常诡异（特别是 simulator 没登 iCloud 的情况）。

真机：连 USB → 顶栏选你的设备 → `⌘R`。

### 4.2 第一次启动可能弹"Trust This Computer?"

真机第一次跑会要求信任电脑。点 Trust + 输设备密码。

### 4.3 验收清单（按顺序跑）

**A. 账号 + CloudKit（核心）**

1. ✅ App 启动 → Onboarding 第 1 页 "Where did your time go?"
2. ✅ 走完 6 步 onboarding → 最后一步选 SIWA → 输 Apple ID 密码 / Face ID → 回到 app 看到 "Signed in as XX"
3. ✅ 点 "Start tracking" → Home 出现，task 列表里有刚才选的预置 task
4. ✅ Settings → 第一行 "Account" 显示头像 + "iCloud sync active"
5. ✅ 创建几个 task + 起几个 timer session
6. **核心验收点**：删 app → 重装 → 再次 SIWA 登录 → **数据全部回来** ✅
7. ✅ Settings → iCloud → Allot 关掉 → 重启 app → Home 顶部出现黄色横条 "Sign in to back up"
8. ✅ 点黄横条 → AccountView 弹出来；点 ✕ → 横条消失，7 天内不再出现

**B. Onboarding**

1. ✅ Settings → About → "Replay Onboarding" 能重启完整流程
2. ✅ Step 2 Prism Demo：不点砖块 Next 灰着；点任意砖块 → 选中态正确（实心 + 其他线框 + 震动 + 下方文字）
3. ✅ Step 3：6 个预置 tag 默认勾选；点 emoji → 弹 alert 输入新 emoji；点色块 → 12 色板展开能选；Add custom 能加自定义
4. ✅ Step 4：只显示 step 3 勾选的 tag；每个下面 2-3 个默认勾选
5. ✅ Step 5：Focus 图标呼吸动画
6. ✅ Step 6：SIWA 按钮 / Maybe later

**C. Widget**

1. 真机长按主屏 → 编辑模式 → 左上 `+` → 搜 "Allot" → 看到 **5 个 widget**
2. 加 `Focus` (Small) → 起一个 session → 数字开始跳动 ✅
3. 加 `Today` (Medium) → 看到迷你 Prism 砖块 + 今日总时长
4. 锁屏 → 加 `Today` (Circular) + `Focus inline` → 锁屏上能看到圆环 + 顶栏一行
5. 加 `Quick start` (Small) → 看到 4 个最近 task → 点任意一格 → app 打开 → 自动开始计时该 task ✅
6. 切 Dark mode → 全部纯黑底白字
7. 切 Light mode → 全部玻璃质感（`.regularMaterial`）

---

## 5. 最容易踩的 5 个坑（我替你预测）

### 坑 1：主 app build 通过但运行 crash 在 ModelContainer

**症状**：黑屏几秒后崩溃，crash log 里有 "iCloud" 字样。

**原因**：iCloud capability 加上了，但 1.4 的 container ID 拼错了（少一个字符、大小写不对、忘记 `iCloud.` 前缀）。

**修法**：去 Apple Developer Console → Containers → 确认 ID 是 `iCloud.com.EL.fire.Allot1`。回 Xcode 1.4，删掉错的 container，刷新，加正确的。

### 坑 2：Sign in with Apple 按钮点了没反应

**症状**：点了 "Sign in with Apple" 按钮，弹一下就关了，没有 Apple ID 弹窗。

**原因**：simulator 没登 iCloud 账号。

**修法**：用真机；或 simulator 里 Settings → Sign in to your iPhone → 登一个 Apple ID。

### 坑 3：Widget 加上去显示 "Unable to Load"

**症状**：widget 在选择列表里看到了，加上桌面后显示一个空盒子或 "Unable to Load"。

**原因**：3.5 漏了某个文件没加到 AllotWidget target。

**修法**：去 Xcode → File Inspector 检查 `WidgetSnapshot.swift` / `DesignTokens.swift` / `PrismMiniView.swift` / `StartTaskIntent.swift` 这 4 个文件的 Target Membership 里 AllotWidget 都勾上了。

### 坑 4：Widget 不显示数据但没报错

**症状**：widget 出现了，但全是占位数据（"Side project / 23m"）或全空。

**原因**：App Group ID 不一致——主 app 写到 group A，widget 读 group B。

**修法**：确认 Allot target 和 AllotWidget target 的 App Groups capability 里都是 **同一个** ID `group.com.EL.fire.Allot1`，**两边都要勾选** ☑。

### 坑 5：Quick Start widget 点击没反应

**症状**：点 Quick Start 的 task 格子没反应或 app 打开但没启动 timer。

**原因**：deep link `allot://focus?start=...` 没被 ContentView 捕获。

**修法**：确认 [ContentView.swift](Allot/Allot/ContentView.swift) 第 98 行附近有 `.onOpenURL { url in handleDeepLink(url) }`。代码里已经写了，但如果你后面手动改过 ContentView 可能改没了。

---

## 6. 我能帮你做的 Xcode 操作（如果你不想动手）

如果你跑到某一步卡住了，告诉我具体哪一步 + 截图（截 capability 配置面板或者错误提示），我能帮你 debug。但 capability 添加这个动作本身只能在 Xcode UI 里点——这不是我偷懒，是 Xcode 把这部分锁在了 UI 里。

---

## 7. 完成判断

下面 3 个都满足，算 setup 完成：

1. **主 app build 通过**（Allot scheme，`⌘B`）
2. **AllotWidget build 通过**（AllotWidget scheme，`⌘B`）
3. **真机跑起来后，删 app → 重装 → SIWA 登录 → 看到之前的数据回来** ← 终极验收

跑完 1+2+3，你就拿到了一个**经得起测试和迭代的 v1 baseline**——以后改设计、删 app、换设备，数据都不会丢。

---

文档结束。卡在哪一步直接告诉我。
