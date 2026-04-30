//
//  RepeatRuleSheet.swift
//  Allot

import SwiftUI

struct RepeatRuleSheet: View {
    @Binding var selectedRule: RepeatRule
    @Environment(\.dismiss) private var dismiss

    private let options: [(RepeatRule, String)] = [
        (.everyDay,     "Every day"),
        (.everyWeekday, "Every weekday (Mon–Fri)"),
        (.everyWeekend, "Every weekend"),
        (.weekly,       "Weekly"),
        (.monthly,      "Monthly"),
        (.yearly,       "Yearly"),
        (.custom,       "Custom…"),
    ]

    var body: some View {
        List(options, id: \.0) { rule, label in
            HStack {
                Text(label)
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                if selectedRule == rule {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Color.accentPrimary)
                        .font(.system(size: 15, weight: .semibold))
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                selectedRule = rule
                dismiss()
            }
        }
        .sheetChrome(
            title: "Repeat",
            trailing: SheetAction(label: "Done") { dismiss() }
        )
        .presentationDetents([.medium])
    }
}
