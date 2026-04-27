//
//  DateStripView.swift
//  Allot
//
//  Monday-anchored 7-day strip. Visible week always contains `selectedDate`.
//  Swipe horizontally → follow finger; release snaps to the prev/next week
//  AND advances `selectedDate` by ±7 days so the same weekday stays selected.
//

import SwiftUI

struct DateStripView: View {
    @Binding var selectedDate: Date

    @GestureState private var dragTranslation: CGFloat = 0

    private var calendar: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.firstWeekday = 2          // Monday
        return c
    }

    private func mondayOf(_ date: Date) -> Date {
        calendar.dateInterval(of: .weekOfYear, for: date)?.start
            ?? calendar.startOfDay(for: date)
    }

    private func weekDays(weeksOffset: Int) -> [Date] {
        let baseMonday = mondayOf(selectedDate)
        guard let monday = calendar.date(byAdding: .day, value: weeksOffset * 7, to: baseMonday)
        else { return [] }
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: monday) }
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            HStack(spacing: 0) {
                weekRow(weekDays(weeksOffset: -1)).frame(width: w)
                weekRow(weekDays(weeksOffset: 0)).frame(width: w)
                weekRow(weekDays(weeksOffset: 1)).frame(width: w)
            }
            .offset(x: -w + dragTranslation)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 10)
                    .updating($dragTranslation) { value, state, _ in
                        state = value.translation.width
                    }
                    .onEnded { value in
                        let threshold = w * 0.25
                        let predicted = value.predictedEndTranslation.width
                        let delta: Int
                        if predicted < -threshold {
                            delta = 1               // swipe left → next week
                        } else if predicted > threshold {
                            delta = -1              // swipe right → prev week
                        } else {
                            delta = 0
                        }
                        if delta != 0 {
                            withAnimation(.spring(response: 0.32, dampingFraction: 0.85)) {
                                if let shifted = calendar.date(byAdding: .day, value: delta * 7, to: selectedDate) {
                                    selectedDate = shifted
                                }
                            }
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                    }
            )
        }
        .frame(height: 64)
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
    }

    private func weekRow(_ days: [Date]) -> some View {
        HStack(spacing: 0) {
            ForEach(days, id: \.self) { day in
                DayCell(
                    date: day,
                    isSelected: calendar.isDate(day, inSameDayAs: selectedDate),
                    isToday: calendar.isDateInToday(day)
                )
                .onTapGesture {
                    if !calendar.isDate(day, inSameDayAs: selectedDate) {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                    selectedDate = day
                }
                .frame(maxWidth: .infinity)
            }
        }
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
                .foregroundStyle(isSelected ? Color.bgPrimary.opacity(0.75) : Color.textTertiary)
                .kerning(0.5)

            Text("\(cal.component(.day, from: date))")
                .font(.system(size: 17, weight: isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? Color.bgPrimary : Color.textPrimary)

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
