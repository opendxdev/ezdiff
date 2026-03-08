import SwiftUI

struct StatsBarView: View {
    let stats: DiffStats
    let leftLanguage: DetectedLanguage?
    let rightLanguage: DetectedLanguage?

    var body: some View {
        HStack(spacing: Constants.Stats.hStackSpacing) {
            HStack(spacing: 4) {
                Text("+\(stats.added)")
                    .foregroundStyle(.green)
                    .fontWeight(.medium)
                Text("added")
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 4) {
                Text("−\(stats.removed)")
                    .foregroundStyle(.red)
                    .fontWeight(.medium)
                Text("removed")
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 4) {
                Text("~\(stats.modified)")
                    .foregroundStyle(.orange)
                    .fontWeight(.medium)
                Text("changed")
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if let left = leftLanguage, let right = rightLanguage, left != right {
                Text("\(left.displayName) ↔ \(right.displayName)")
                    .foregroundStyle(.secondary)
            }
        }
        .font(.system(.caption, design: .default))
        .padding(.horizontal, Constants.Stats.horizontalPadding)
        .padding(.vertical, Constants.Stats.verticalPadding)
        .background(.bar)
        .overlay(alignment: .bottom) { Divider() }
    }
}
