# AllotLiveActivity — Xcode setup

The widget extension target must be created via Xcode UI (manually editing
`project.pbxproj` to add a target is too risky). All source files are already
on disk. Follow these steps once, then everything builds.

## 1. Create the target

1. Open `Allot/Allot.xcodeproj` in Xcode.
2. **File → New → Target…**
3. Select **iOS → Widget Extension**, click **Next**.
4. Settings:
   - Product Name: `AllotLiveActivity`
   - Team: `526LTP6Z7D` (same as main app)
   - Bundle Identifier: `com.FL.fire.Allot.LiveActivity` (auto-derived)
   - Language: Swift
   - **Include Live Activity**: ✅ checked
   - **Include Configuration App Intent**: ❌ unchecked
   - Embed in Application: `Allot`
5. Click **Finish**, then **Activate** if prompted.

Xcode generates a stub `AllotLiveActivity.swift`, an attributes file, a
`AllotLiveActivityBundle.swift`, and an Info.plist. **Delete all four**
generated files (move to trash). The repo already provides replacements at
`Allot/AllotLiveActivity/`.

## 2. Add existing source files to the new target

In Xcode's project navigator, locate the newly created `AllotLiveActivity`
group. Right-click it → **Add Files to "Allot"…** and add:

- `Allot/AllotLiveActivity/AllotLiveActivityBundle.swift`
- `Allot/AllotLiveActivity/FocusActivityWidget.swift`

Make sure target membership for both is **AllotLiveActivity only** (uncheck
the main `Allot` target).

## 3. Share the attributes + design tokens

Both targets need access to the activity payload type and the color tokens.
Select each of the following files in the project navigator and, in the
**File Inspector** (right pane) **Target Membership**, tick **both** the
`Allot` target **and** the `AllotLiveActivity` target:

- `Allot/Allot/Activities/FocusActivityAttributes.swift`
- `Allot/Allot/Views/Components/DesignTokens.swift`

If `Activities` doesn't appear yet, drag the folder into the project
navigator first (Add Files, no target membership needed for the folder
itself; tick both targets for the .swift inside).

## 4. Verify Info.plist

The widget extension's `Info.plist` should already contain:

```xml
<key>NSExtension</key>
<dict>
    <key>NSExtensionPointIdentifier</key>
    <string>com.apple.widgetkit-extension</string>
</dict>
```

## 5. Build & run

- Select the `Allot` scheme + an iPhone 16 Pro simulator.
- ⌘R. The main app should build and launch; the widget extension is embedded.
- Edit a tag in Settings → Tags, set its emoji.
- Start a focus session, swipe up to background. The Dynamic Island shows
  emoji + live timer. Long-press to expand.

## Troubleshooting

- **"Cannot find type FocusActivityAttributes"** — target membership for
  `FocusActivityAttributes.swift` is missing the widget extension.
- **"Cannot find Color.tagColor"** — `DesignTokens.swift` isn't a member of
  the widget extension target.
- **Live Activity never appears** — confirm `INFOPLIST_KEY_NSSupportsLiveActivities = YES`
  is in main app build settings (already added in this commit). Also check
  Settings → Face ID → Live Activities is on, and the simulator is iOS 16.1+.
