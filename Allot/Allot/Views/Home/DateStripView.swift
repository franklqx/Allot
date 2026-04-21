//
//  DateStripView.swift
//  Allot
//
//  7-day week strip. Swipe left/right to advance/retreat one full week.

import SwiftUI

struct DateStripView: View {
    @Binding var selectedDate: Date

    @State private var weekOffset: Int = 0
    @GestureState private var dragOffset: CGFloat = 0

    private let cal = Calendar.current
    private let dayLetters = ["SUN","MON","TUE","WED","THU","FRI","SAT"]

    private var weekDays: [Date] {
        // Monday-anchored week for the current weekOffset
        let now = Date()
        let todayWeekday = cal.component(.weekday, from: now)  // 1=Sun
        // Days since Monday
        let daysFromMonday = (todayWeekday + 5) % 7
        let thisMonday = cal.date(byAdding: .day, value: -daysFromMonday + (weekOffset * 7), to: cal.startOfDay(for: now))!
        return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: thisMonday) }
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(weekDays, id: \.self) { day in
                DayCell(
                    date: day,
                    isSelected: cal.isDate(day, inSameDayAs: selectedDate),
                    isToday: cal.isDateInToday(day)
                )
                .onTapGesture { selectedDate = day }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
        .gesture(
            DragGesture(minimumDistance: 30)
                .onEnded { value in
                    let threshold: CGFloat = 50
                    if value.translation.width < -threshold {
                        weekOffset += 1
                    } else if value.translation.width > threshold {
                        weekOffset -= 1
                    }
                }
        )
    }
}

private struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool

    private let cal = Calendar.current

    var body: some View {
        VStack(spacing: 4) {
            let weekday = cal.component(.weekday, from: date)
            let letters = ["SUN","MON","TUE","WED","THU","FRI","SAT"]
            Text(letters[weekday - 1])
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(isSelected ? Color.white.opacity(0.75) : Color.textTertiary)
                .kerning(0.5)

            Text("\(cal.component(.day, from: date))")
                .font(.system(size: 17, weight: isSelected ? .semibold : .regular, design: .monospaced))
                .foregroundStyle(isSelected ? .white : Color.textPrimary)

            // Today dot (only when not selected)
            Circle()
                .fill(Color.accentPrimary)
                .frame(width: 4, height: 4)
                .opacity(isToday && !isSelected ? 1 : 0)
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(isSelected ? Color.accentPrimary : .clear)
        )
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}
