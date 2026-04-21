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
        return sessions
            .filter { cal.isDate($0.startAt, inSameDayAs: date) }
            .reduce(0) { $0 + effectiveDuration($1) }
    }

    var workedSecondsTotal: Int {
        sessions.reduce(0) { $0 + effectiveDuration($1) }
    }

    func workedSecondsThisWeek() -> Int {
        let cal = Calendar.current
        let now = Date()
        let start = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
        let end   = cal.date(byAdding: .weekOfYear, value: 1, to: start)!
        return sessions.filter { $0.startAt >= start && $0.startAt < end }.reduce(0) { $0 + effectiveDuration($1) }
    }

    func workedSecondsThisMonth() -> Int {
        let cal = Calendar.current
        let now = Date()
        let start = cal.date(from: cal.dateComponents([.year, .month], from: now))!
        let end   = cal.date(byAdding: .month, value: 1, to: start)!
        return sessions.filter { $0.startAt >= start && $0.startAt < end }.reduce(0) { $0 + effectiveDuration($1) }
    }

    /// Set of day-of-month integers that have at least one session in a given year/month.
    func sessionDays(year: Int, month: Int) -> Set<Int> {
        let cal = Calendar.current
        return sessions.reduce(into: Set<Int>()) { result, s in
            let c = cal.dateComponents([.year, .month, .day], from: s.startAt)
            if c.year == year, c.month == month, let d = c.day { result.insert(d) }
        }
    }

    // MARK: Private

    private func effectiveDuration(_ session: TimeSession) -> Int {
        guard let end = session.endAt else { return 0 }
        return max(0, Int(end.timeIntervalSince(session.startAt)) - session.totalPausedSeconds)
    }
}
