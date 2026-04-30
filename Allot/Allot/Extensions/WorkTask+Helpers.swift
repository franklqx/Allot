//
//  WorkTask+Helpers.swift
//  Allot

import Foundation

extension WorkTask {

    // MARK: Scheduling

    func isScheduled(on date: Date) -> Bool {
        let cal = Calendar.current
        switch type {
        case .once:
            guard let scheduledDate else { return false }
            return cal.isDate(scheduledDate, inSameDayAs: date)
        case .recurring:
            // One-off "Add to today" overrides — these show the task even
            // when it's not on the recurring schedule for that date.
            if oneOffDates.contains(where: { cal.isDate($0, inSameDayAs: date) }) {
                return true
            }
            guard let rule = repeatRule else { return true }
            let weekday    = cal.component(.weekday,    from: date)  // 1=Sun … 7=Sat
            let dayOfMonth = cal.component(.day,        from: date)
            switch rule {
            case .everyDay:     return true
            case .everyWeekday: return (2...6).contains(weekday)        // Mon–Fri
            case .everyWeekend: return weekday == 1 || weekday == 7
            case .weekly:       return repeatCustomDays.contains(weekday)
            case .monthly:      return repeatCustomDays.contains(dayOfMonth)
            case .yearly:       return false                             // Phase 2
            case .custom:       return repeatCustomDays.contains(weekday)
            }
        }
    }

    /// True when the task is archived (paused / hidden from Home).
    /// Sessions stay in history; user can restore the task from Settings.
    var isArchived: Bool { archivedAt != nil }

    // MARK: Completion

    func isCompleted(on date: Date) -> Bool {
        let cal = Calendar.current
        return completedDates.contains { cal.isDate($0, inSameDayAs: date) }
    }

    func markCompleted(on date: Date) {
        let cal = Calendar.current
        guard !completedDates.contains(where: { cal.isDate($0, inSameDayAs: date) }) else { return }
        completedDates.append(cal.startOfDay(for: date))
    }

    func markIncomplete(on date: Date) {
        let cal = Calendar.current
        completedDates.removeAll { cal.isDate($0, inSameDayAs: date) }
    }

    // MARK: Duration

    func workedSeconds(on date: Date) -> Int {
        let cal = Calendar.current
        return (sessions ?? [])
            .filter { cal.isDate($0.startAt, inSameDayAs: date) }
            .reduce(0) { $0 + effectiveDuration($1) }
    }

    var workedSecondsTotal: Int {
        (sessions ?? []).reduce(0) { $0 + effectiveDuration($1) }
    }

    func workedSecondsThisWeek() -> Int {
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 2     // Monday — week always runs Mon→Sun.
        let now = Date()
        let start = cal.dateInterval(of: .weekOfYear, for: now)?.start
            ?? cal.startOfDay(for: now)
        let end   = cal.date(byAdding: .weekOfYear, value: 1, to: start)!
        return (sessions ?? []).filter { $0.startAt >= start && $0.startAt < end }.reduce(0) { $0 + effectiveDuration($1) }
    }

    func workedSecondsThisMonth() -> Int {
        let cal = Calendar.current
        let now = Date()
        let start = cal.date(from: cal.dateComponents([.year, .month], from: now))!
        let end   = cal.date(byAdding: .month, value: 1, to: start)!
        return (sessions ?? []).filter { $0.startAt >= start && $0.startAt < end }.reduce(0) { $0 + effectiveDuration($1) }
    }

    /// Set of day-of-month integers that have at least one session in a given year/month.
    func sessionDays(year: Int, month: Int) -> Set<Int> {
        let cal = Calendar.current
        return (sessions ?? []).reduce(into: Set<Int>()) { result, s in
            let c = cal.dateComponents([.year, .month, .day], from: s.startAt)
            if c.year == year, c.month == month, let d = c.day { result.insert(d) }
        }
    }

    // MARK: Display

    /// The emoji prefix on the title, or empty string if none.
    var titleEmojiPrefix: String {
        Self.splitEmojiPrefix(from: title).emoji
    }

    /// The title with the emoji prefix stripped.
    var titleWithoutEmoji: String {
        Self.splitEmojiPrefix(from: title).title
    }

    /// Title rendered for a given emoji-display preference.
    /// Pass `showEmoji = false` to strip the prefix everywhere a task title is shown.
    func displayTitle(showEmoji: Bool) -> String {
        showEmoji ? title : titleWithoutEmoji
    }

    static func splitEmojiPrefix(from rawTitle: String) -> (emoji: String, title: String, hasEmoji: Bool) {
        let trimmed = rawTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let first = trimmed.first, first.isEmojiGlyph else {
            return ("", rawTitle, false)
        }
        let remaining = String(trimmed.dropFirst()).trimmingCharacters(in: .whitespaces)
        return (String(first), remaining, true)
    }

    /// Build "💻Task name" from an optional emoji + title, with empty emoji preserved.
    static func decoratedTitle(emoji: String, title: String) -> String {
        let cleanEmoji = emoji.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanEmoji.isEmpty else { return title }
        return "\(cleanEmoji)\(title)"
    }

    // MARK: Reuse

    /// Re-target a task so it shows up on a given date. For Once tasks this
    /// moves the scheduled date; for Recurring tasks it appends a one-off
    /// override (the underlying repeat rule stays untouched). Either way we
    /// clear any completion mark on that date and unarchive the task.
    func reuseFor(date: Date) {
        let cal = Calendar.current
        let day = cal.startOfDay(for: date)
        switch type {
        case .once:
            scheduledDate = day
        case .recurring:
            if !oneOffDates.contains(where: { cal.isDate($0, inSameDayAs: day) }) {
                oneOffDates.append(day)
            }
        }
        completedDates.removeAll { cal.isDate($0, inSameDayAs: day) }
        archivedAt = nil
    }

    // MARK: Private

    private func effectiveDuration(_ session: TimeSession) -> Int {
        guard let end = session.endAt else { return 0 }
        return max(0, Int(end.timeIntervalSince(session.startAt)) - session.totalPausedSeconds)
    }
}

// MARK: - Emoji glyph detection

extension Character {
    /// Whether this character renders as a standalone emoji presentation.
    /// Used by the title-prefix splitter and the Live Activity icon resolver.
    var isEmojiGlyph: Bool {
        unicodeScalars.contains { scalar in
            scalar.properties.isEmojiPresentation
                || (scalar.properties.isEmoji && scalar.value > 0x238C)
        }
    }
}
