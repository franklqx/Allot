# Allot App — AI Design Prompt

Use this document as a paste-in brief for AI design tools (v0.dev, Claude, Figma AI,
Midjourney, DALL-E, etc.). Each section is self-contained so you can paste just the
part you need, or paste the whole thing for a complete brief.

---

## MASTER BRIEF (paste this entire block for full-context generation)

```
Design a native iOS 18 iPhone app called "Allot" — a personal time tracking app for
independent developers, freelancers, and multi-project creators. The app is an Apple
Design Award quality product that follows Apple's Human Interface Guidelines strictly.

PLATFORM
- iPhone only, iOS 18+
- Screen: 390 x 844pt (iPhone 15 Pro canvas)
- Safe area: 59pt top (status bar + notch), 34pt bottom (home indicator)
- Navigation: bottom tab bar with 2 tabs — "Home" and "Insights"
- Language: English

DESIGN PHILOSOPHY
Clean, calm, non-punitive. Inspired by Apple Health, Oura Ring, and Gentler Streak.
The app does not create anxiety — it simply shows where your time went. No red streaks,
no completion pressure. Positive reinforcement only.

The interface follows Apple's own website/system design DNA:
- SF Pro Display for headings (20pt+), SF Pro Text for body/labels (<20pt)
- Near-black (#1d1d1f) on light backgrounds, white on dark backgrounds
- Single accent: Apple Blue (#0071e3) for interactive elements ONLY
- Background: light gray (#f5f5f7), not pure white — the slight warmth prevents sterility
- Liquid glass (backdrop-filter blur + translucency) used sparingly: tab bar, FAB only
- No gradients, no textures, no decorative patterns — solid colors only

COLOR PALETTE
- Page background (light mode): #f5f5f7
- Page background (dark mode): #000000
- Primary text (light): #1d1d1f
- Primary text (dark): #ffffff
- Secondary text: rgba(0,0,0,0.4) on light / rgba(255,255,255,0.4) on dark
- Accent (interactive only): #0071e3 (Apple Blue)
- Active timer accent: #0071e3
- Card surface (light): #ffffff with shadow rgba(0,0,0,0.08) 0px 2px 12px
- Card surface (dark): #1c1c1e
- Separator: rgba(0,0,0,0.08)
- Tab bar: rgba(250,250,250,0.92) with backdrop-filter blur(20px) saturate(180%)
- Destructive: #ff3b30 (system red, iOS standard)
- Success/done: rgba(0,0,0,0.25) text (muted, not celebratory)

TYPOGRAPHY (SF Pro family only)
- Nav date heading: SF Pro Text, 17pt, weight 600, letter-spacing -0.4pt
- Large date (timeline mode): SF Pro Display, 30pt, weight 800, letter-spacing -0.5pt
- Task title (default): SF Pro Text, 16pt, weight 600, line-height 1.2
- Task title (expanded): SF Pro Display, 18pt, weight 700, line-height 1.15
- Duration / secondary: SF Pro Text, 13pt, weight 400, rgba(0,0,0,0.4)
- Timer running: SF Pro Display (monospaced digits), 22pt, weight 700, #0071e3
- Section label (AM / PM / UNSCHEDULED): SF Pro Text, 11pt, weight 600,
  letter-spacing +0.8pt, rgba(0,0,0,0.35), ALL CAPS
- Hour mark: SF Pro Text, 11pt, weight 500, rgba(0,0,0,0.35)
- Tab label: SF Pro Text, 10pt, weight 600
- Button label: SF Pro Text, 15pt, weight 600

COMPONENT SPECS

Tab Bar
- Height: 83pt (including home indicator zone)
- Active tab: label color #000000, 2pt underline bar (24pt wide) below label in #000000
- Inactive tab: label color rgba(0,0,0,0.3), no underline
- Background: rgba(250,250,250,0.92), backdrop-filter blur(20px) saturate(180%)
- Top border: 0.5pt solid rgba(0,0,0,0.2)
- No icons — text labels only ("Home", "Insights")

FAB (Floating Action Button)
- Position: bottom-right, 20pt from right edge, 90pt from bottom edge
- Size: 56pt diameter, circular
- State TODAY: shows "+" symbol, 26pt weight 200, white on dark background
  Background: liquid glass — rgba(29,29,31,0.85) with backdrop-filter blur(16px)
  Box-shadow: 0pt 4pt 14pt rgba(0,0,0,0.3)
- State NOT-TODAY: shows "Today" text, 13pt SF Pro Text weight 600, same glass treatment

Nav Bar
- Height: 56pt
- Center: current date as "Thursday, Apr 17" — SF Pro Text 17pt weight 600
- Right: calendar icon (SF Symbol: calendar or calendar.badge.clock), 22pt, #1d1d1f
- No back button, no left element on Home
- Bottom border: none (separator handled by list or section gap)

Task Cards (default list view)
- Full-width rows with 16pt horizontal padding
- Height: 56pt minimum (grows with content)
- Title at 16pt SF Pro Text weight 600
- Below title (if target duration set): "X min goal" or "X hr goal" in 12pt rgba(0,0,0,0.4)
- Separator: 1pt rgba(0,0,0,0.06) line, 16pt left inset
- No card background in default list — rows are on the page background
- Tapping expands the row in-place (Pill Stack variant) OR navigates to timer

Start / Log Time / Done Buttons (expanded task)
- Appear below task title when row is expanded
- "Start": filled pill, #1d1d1f background, white text, 15pt weight 600, 8pt radius
- "Log Time": outlined pill, #1d1d1f border, #1d1d1f text, 15pt weight 600, 8pt radius
- "Done": ghost pill, rgba(0,0,0,0.15) text, no border, 15pt weight 400
- Pills: 34pt height, horizontal padding 16pt
- Gap between pills: 8pt

Active Timer Card (when a task is running)
- Appears above the task list, below the nav bar
- Left: 3pt vertical accent bar in #0071e3
- Task name: 16pt SF Pro Text weight 600 #1d1d1f
- Status: "Running" in 12pt rgba(0,0,0,0.4)
- Right: live timer in "1:24:07" format, SF Pro Display 22pt weight 700 #0071e3
- Background: #ffffff, corner radius 12pt, shadow rgba(0,0,0,0.08) 0 2pt 12pt
- Margin: 16pt left/right, 8pt bottom gap before task list

Timeline Column (Variant D)
- Left column: 58pt wide, shows hour marks (7 AM, 8 AM... 12 PM) at 72pt intervals
- Hour label: 11pt SF Pro Text weight 500 rgba(0,0,0,0.35), right-aligned
- Hour line: 1pt vertical rgba(0,0,0,0.08) extending rightward from each mark
- Task area: flex-1, tasks positioned absolutely at their scheduled time
- Each task: 4pt wide vertical accent bar (#1d1d1f) + task name + duration
- Task name: 16pt SF Pro Text weight 700 #1d1d1f
- Duration below: 12pt rgba(0,0,0,0.4)
- Height of accent bar = proportional to task duration at 72pt per hour

Unscheduled Section (bottom of timeline view)
- Label: "UNSCHEDULED" in section label style (see typography)
- Task items: 15pt SF Pro Text weight 400, 4pt bottom border rgba(0,0,0,0.06)
- No start/stop controls — these are tasks without a scheduled time

HOME SCREEN — DEFAULT STATE (no active timer, tasks listed)

Layout top to bottom:
1. Status bar (system, 50pt)
2. Nav bar: center "Thursday, Apr 17", right calendar icon (56pt)
3. Task list section:
   - Section header "AM" (32pt height) — if any AM tasks
   - Task rows (56pt each, flat list, no cards)
   - Section header "PM" — if any PM tasks
   - More task rows
   - Section "UNSCHEDULED" — tasks with no time
4. FAB in bottom-right (floating, above tab bar)
5. Tab bar at bottom

Empty state (no tasks yet):
- Center of screen: SF Symbol "timer" at 48pt, rgba(0,0,0,0.2)
- Below: "No tasks yet" SF Pro Text 17pt weight 600 #1d1d1f
- Below: "Tap + to add your first task" SF Pro Text 15pt rgba(0,0,0,0.4)

HOME SCREEN — ACTIVE TIMER STATE

Same as default, plus:
- Active Timer Card pinned below nav bar (white card, blue timer, accent bar)
- The running task row in the list shows a pulsing blue dot before its title
- FAB remains visible

HOME SCREEN — TIMELINE VIEW (alternate layout)

Triggered by: swipe right on list, or user preference setting
Layout:
1. Status bar
2. Nav bar: left "APR 17" in 30pt Display weight 800, right calendar icon
3. Horizontal time-column layout:
   - Left: 58pt hour mark column (7 AM to 11 PM)
   - Right: task area, tasks placed at their scheduled time
4. Unscheduled section pinned above tab bar
5. FAB above unscheduled section
6. Tab bar

MANUAL TIME ENTRY SHEET

Triggered by: "Log Time" button on a task
Presentation: bottom sheet, 85% screen height, background #ffffff, top 12pt radius

Layout:
1. Handle bar: 4 x 36pt, rounded, rgba(0,0,0,0.2), centered at top
2. Title: "Log Time" SF Pro Display 22pt weight 700 #1d1d1f, 20pt from top
3. Date selector: row with left/right chevrons and date text, SF Pro Text 17pt
4. Time range visualizer: horizontal bar from start time to end time
   - Bar: 4pt height, #0071e3, rounded ends
   - Start/end handles: 24pt circles, white with #0071e3 border
5. Start time label: large SF Pro Display 48pt weight 300 — draggable
6. End time label: large SF Pro Display 48pt weight 300 — draggable
7. Haptic feedback on 5-minute snaps
8. Task selector: "Assigned to: [Task Name]" pill at bottom
9. Quick categories: "Break", "Meal", "Commute", "Other" as ghost pills
10. Save button: full-width, 50pt height, #1d1d1f background, white text, 12pt radius

INSIGHTS SCREEN

Nav: "Insights" centered 22pt SF Pro Display weight 700
Segment picker: "Day / Week / Month / Year" as pill selector, 14pt

Day view:
- Donut chart (180pt diameter): time by tag/category
- Below: ranked list of tags with time spent and percentage bar
- "Untracked" shown in rgba(0,0,0,0.2) — not highlighted as failure

Week view:
- 7-column bar chart: bars scaled to hours, colored by dominant tag
- Below: same ranked list

INTERACTIONS AND MOTION
- List rows expand with spring animation (damping 0.7, response 0.4s)
- Timer digits use monospaced tabular figures, update every second
- FAB press: scale down to 0.92 on touch, spring back on release
- Sheet presentation: standard iOS spring with slight overshoot
- Tab switch: crossfade 0.2s, no slide
- Haptic: medium impact on start timer, light on pause, notification on complete

DO NOT
- Do not use gradients on any background
- Do not use more than one accent color (only #0071e3)
- Do not use rounded corners above 16pt on list rows
- Do not add drop shadows to list rows in default list mode
- Do not add icons to the tab bar (text only)
- Do not show streaks, scores, or completion percentages on Home
- Do not use SF Symbol icons inside task rows — text only
- Do not center-align body or task text — always left-aligned

REFERENCE APPS FOR VISUAL TONE
- Apple Health: system clarity, summary cards, charts, readability first
- Oura Ring: calm, soft data presentation, no alarm/urgency
- Gentler Streak: non-punitive progress display, encouraging tone
- Notion: block structure, whitespace, heading hierarchy
- Apple Clock / Timer: monospaced digits, clear state machine UI
```

---

## SCREEN-SPECIFIC PROMPTS

### Prompt: Home Screen (Default, Light Mode)

```
iPhone 15 Pro (390x844pt) iOS 18 app screen, light mode.
Background: #f5f5f7. Status bar black, 9:41.

Top nav bar (56pt tall):
- Center text: "Thursday, Apr 17", SF Pro Text 17pt weight 600, color #1d1d1f
- Right: calendar icon (outline), 22pt, #1d1d1f
- No left element

Task list, flat (no card backgrounds), full width, 16pt side padding:
- Section header "AM" — 11pt SF Pro Text weight 600 letter-spacing +0.8pt rgba(0,0,0,0.35)
  - Row: "Morning run" | below "45 min goal" 12pt rgba(0,0,0,0.4) | 56pt row height
  - Row: "Deep work: Allot app" | below "2 hr goal"
  - Separator lines between rows: 1pt rgba(0,0,0,0.06) with 16pt left inset
- Section header "PM"
  - Row: "Reply emails"
- Section header "UNSCHEDULED"
  - Row: "Study SwiftUI"
  - Row: "Read: 30 min"
  - Row: "Plan next week"

FAB bottom-right:
- 56pt circle, position 20pt from right, 90pt from bottom
- Background: rgba(29,29,31,0.85) frosted glass
- "+" symbol 26pt weight 200 white

Tab bar (83pt from bottom):
- rgba(250,250,250,0.92) frosted glass, 0.5pt top border rgba(0,0,0,0.2)
- "Home" active: black text 10pt weight 600, 2pt black underline 24pt wide below label
- "Insights" inactive: rgba(0,0,0,0.3) text, no underline

Photorealistic iOS 18 interface mockup on white background.
```

### Prompt: Home Screen (Active Timer Running, Light Mode)

```
iPhone 15 Pro (390x844pt) iOS 18 app, light mode. Background: #f5f5f7.

Status bar, 9:41.

Nav bar (56pt): center "Thursday, Apr 17" SF Pro Text 17pt weight 600.

Active timer card (pinned below nav, 16pt side margins, 12pt corner radius):
- Background: #ffffff, shadow rgba(0,0,0,0.08) 0 2pt 12pt
- Left: 3pt vertical bar, color #0071e3, height 52pt, 2pt corner radius
- Left of bar: 10pt gap
- "Deep work: Allot app" SF Pro Text 16pt weight 600 #1d1d1f
- Below task name: "Running" SF Pro Text 12pt rgba(0,0,0,0.4)
- Right: "1:24:07" SF Pro Display 22pt weight 700 #0071e3 (monospaced digits)

Task list below:
- First row "Deep work: Allot app" has a 6pt pulsing filled circle in #0071e3 before text
- Remaining rows: "Morning run", "Reply emails", "Study SwiftUI"
- Separator lines as before

FAB and tab bar same as default state.

Photorealistic iOS 18 interface.
```

### Prompt: Home Screen (Timeline View, Light Mode)

```
iPhone 15 Pro (390x844pt) iOS 18 app, light mode. Background: #f5f5f7.

Status bar, 9:41 black.

Nav bar (56pt):
- Left: "APR 17" SF Pro Display 30pt weight 800 letter-spacing -0.5pt #000000
- Right: calendar emoji or SF Symbol icon

Content area = two-column horizontal layout (no scrolling shown):

Left column (58pt wide, left-aligned from screen edge):
- "7 AM" label: 11pt weight 500 rgba(0,0,0,0.35), right-aligned within column
- Horizontal rule rightward: 1pt rgba(0,0,0,0.08)
- Same for 8 AM, 9 AM, 10 AM, 11 AM, 12 PM
- Each row = 72pt height

Right task column (flex-1):
At 7 AM position (top: 0):
- 4pt x 36pt vertical bar, color #1d1d1f, 2pt corner radius
- Right of bar: "Morning run" 16pt weight 700 #1d1d1f
- Below: "45 min goal" 12pt rgba(0,0,0,0.4)

At 9 AM position (top: 144pt):
- Same 4pt vertical bar, 48pt tall
- "Deep work: Allot app" 16pt weight 700 #1d1d1f
- Below: "2 hr goal"

At 11 AM position (top: 288pt):
- 4pt x 30pt vertical bar
- "Reply emails" 16pt weight 700

Bottom section labeled "UNSCHEDULED" (pinned above FAB):
- Label: "UNSCHEDULED" 11pt SF Pro Text weight 600 letter-spacing +0.8pt rgba(0,0,0,0.35)
- List: "Study SwiftUI", "Read: 30 min", "Plan next week" — each 15pt SF Pro Text weight 400
- Separated by 1pt rgba(0,0,0,0.06) lines

FAB: 56pt circle, dark frosted glass, "+" white, 20pt from right, 90pt from bottom.
Tab bar at bottom: "Home" active underlined, "Insights" inactive.

Photorealistic iOS 18 interface.
```

### Prompt: Manual Time Entry Sheet

```
iPhone 15 Pro (390x844pt) iOS 18. Shows Home screen underneath (blurred) with
a bottom sheet slid up 85% of screen height.

Sheet:
- Background: #ffffff, top corners 12pt radius
- Handle bar: 36pt wide, 4pt tall, rgba(0,0,0,0.2), centered, 8pt from top edge

Sheet content:
- "Log Time" SF Pro Display 22pt weight 700 #1d1d1f, 20pt from handle, left-aligned, 20pt side pad
- Date row: "<" icon, "Thu, Apr 17" center 15pt SF Pro Text weight 600, ">" icon
  — all 44pt height, 20pt side padding

Time range visualizer (center of sheet):
- Full width minus 32pt side pad
- 4pt tall horizontal bar in #0071e3, rounded ends
- Left handle: 24pt circle, white fill, 2pt #0071e3 stroke — "7:00 AM" below in 13pt
- Right handle: same — "8:30 AM" below
- "1h 30m" label centered above bar, 13pt weight 600 #1d1d1f

Large time display:
- "7:00" left-aligned 48pt SF Pro Display weight 300 #1d1d1f
- "8:30" right-aligned 48pt SF Pro Display weight 300 #1d1d1f

Task assignment row:
- "Assigned to:" 13pt rgba(0,0,0,0.4)
- "Deep work: Allot app" pill: 13pt weight 600 #1d1d1f, 8pt padding, 8pt radius #f5f5f7 bg

Quick-add category pills (horizontal scroll):
- "Break", "Meal", "Commute", "Other"
- Each: 13pt SF Pro Text weight 400, 8pt radius, #f5f5f7 bg, 32pt height, 14pt h-pad
- 8pt gap between pills

Save button (full width, 20pt side margins):
- 50pt height, 12pt corner radius, #1d1d1f background
- "Save" SF Pro Text 17pt weight 600 #ffffff centered

Photorealistic iOS 18 sheet interface.
```

### Prompt: Insights Screen — Day View

```
iPhone 15 Pro (390x844pt) iOS 18. Light mode. Background: #f5f5f7.

Status bar 9:41.

Nav: "Insights" centered SF Pro Display 22pt weight 700 #1d1d1f. No back button.

Segment control (below nav, 16pt margins):
- Pill-shaped container: #e5e5ea background, 10pt radius
- 4 segments: "Day" | "Week" | "Month" | "Year"
- Active "Day": #ffffff background, shadow, SF Pro Text 13pt weight 600 #1d1d1f
- Inactive: SF Pro Text 13pt weight 400 rgba(0,0,0,0.4)

Content:

Date context: "Today, Apr 17" — SF Pro Text 15pt weight 400 rgba(0,0,0,0.4), 16pt margin, 12pt below segment

Donut chart (centered, 180pt diameter):
- Segments by tag/category color:
  - Deep work: #0071e3 (dominant, ~60%)
  - Morning run: #34c759 (green, ~20%)
  - Other: #ff9f0a (orange, ~15%)
  - Untracked: rgba(0,0,0,0.1) dashed stroke only (not filled) — not shown as failure
- Center of donut: "5h 24m" SF Pro Display 26pt weight 700, below "tracked today" 13pt rgba(0,0,0,0.4)

Ranked tag list below chart (each row 52pt height, 16pt side padding):
Row format: [10pt colored dot] [Tag name 15pt weight 600 #1d1d1f] [time right-aligned 15pt rgba(0,0,0,0.4)]
- Below tag name: thin progress bar (4pt height, tag color, up to 80% width = 100% of day)
- "Deep work" | 3h 14m — bar at 60%
- "Morning run" | 1h 08m — bar at 22%
- "Reply emails" | 42m — bar at 13%
- Separator: 1pt rgba(0,0,0,0.06)

Tab bar: same as Home screen, "Insights" active underlined.

Photorealistic iOS 18 interface.
```

---

## SHORT PROMPT (for Midjourney / image generation)

```
iOS 18 iPhone app "Allot", personal time tracker. Home screen, light mode.
Clean Apple-style UI: #f5f5f7 background, SF Pro typography, black near-black text,
Apple Blue (#0071e3) accent on running timer only. Flat task list with AM and PM
sections, each task row shows title and duration goal. Dark frosted-glass FAB bottom-right
with "+" symbol. Frosted glass tab bar at bottom, "Home" and "Insights" text-only tabs
with black underline on active. Live timer card pinned below nav bar showing "1:24:07"
in blue. Ultra-clean, Apple Design Award quality, minimal, calm. iPhone 15 Pro frame.
Photorealistic UI screenshot. 390x844px.
```

---

## PROMPT FOR v0.dev / CLAUDE CODE GENERATION

```
Build a pixel-perfect iOS 18 SwiftUI app screen for "Allot" — a personal time tracker.

Specs:
- Platform: iPhone 15 Pro, SwiftUI, iOS 18+
- Background color: Color(hex: "#f5f5f7")

Screen: Home (active timer state)

Components:
1. Navigation bar (56pt):
   - Centered text: "Thursday, Apr 17", font .headline .fontWeight(.semibold)
   - Right toolbar: Image(systemName: "calendar") 22pt

2. Active timer card (below nav, 16pt margins, cornerRadius 12):
   - White background, shadow(color: .black.opacity(0.08), radius: 12, y: 2)
   - Left: Rectangle().frame(width: 4).foregroundColor(Color(hex: "#0071e3")).cornerRadius(2)
   - Task name: Text("Deep work: Allot app").font(.system(size: 16, weight: .semibold))
   - Status: Text("Running").font(.caption).foregroundColor(.secondary)
   - Right: Text("1:24:07").font(.system(size: 22, weight: .bold, design: .monospaced))
              .foregroundColor(Color(hex: "#0071e3"))

3. Task list (flat rows, no card background):
   - Section "AM": ForEach tasks where scheduledTime AM
   - Row: VStack { Text(title).font(.system(size: 16, weight: .semibold))
           if let dur = targetDuration { Text("\(dur/60) min goal").font(.caption).opacity(0.4) } }
   - Divider().padding(.leading, 16).opacity(0.4)
   - Section "UNSCHEDULED": tasks without scheduledTime

4. FAB (ZStack overlay, bottom-right):
   - Circle 56pt diameter
   - .background(.ultraThinMaterial) with .background(Color.black.opacity(0.85))
   - .cornerRadius(28)
   - .shadow(radius: 14, y: 4)
   - Text("+").font(.system(size: 26, weight: .ultraLight)).foregroundColor(.white)
   - .padding(.trailing, 20).padding(.bottom, 90)

5. Tab bar:
   - Custom tab bar, height 83pt
   - .background(.ultraThinMaterial)
   - .overlay(Rectangle().frame(height: 0.5).foregroundColor(.black.opacity(0.2)), alignment: .top)
   - Tab items: text-only "Home" and "Insights"
   - Active: Text.fontWeight(.semibold) + Rectangle() 2pt height 24pt width below
   - Inactive: opacity 0.3, no underline
```

---

## NOTES FOR THE DESIGNER

**Which variant to use as primary direction:**

- **Variant A (Arctic Light)**: Best starting point for MVP. Ultra-clean, hardest to
  get wrong. Use when you want maximum readability and fast development.

- **Variant B (Midnight Focus)**: Premium feel, great for power users. Build after A is
  solid — dark mode is a Phase 2 item.

- **Variant C (Pill Stack)**: Best interaction model — expand-in-place for Start/Log Time/Done.
  The card grouping adds information density. Recommend combining C's interaction pattern
  with A's overall visual tone.

- **Variant D (Brutalist Timeline)**: Best for "scheduled" tasks view. The hour-column
  layout is the right mental model for users who schedule their day. Implement as an
  alternate view mode accessible by toggle.

**Recommended first screen to build:** Variant A layout + Variant C's expanded row
interaction (tap a task, it expands in-place to show Start / Log Time / Done buttons).

**Key detail to get right:** The FAB. It must be genuine liquid glass — not just a
semi-transparent circle. On real devices: `.ultraThinMaterial` background + dark overlay
+ a 16pt blur. The moment it looks wrong, the whole screen feels off.
```
