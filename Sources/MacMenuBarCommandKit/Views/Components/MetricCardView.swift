import SwiftUI

public struct MetricCardView: View {
    private let metric: MetricCard

    public init(metric: MetricCard) {
        self.metric = metric
    }

    public var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: metric.systemImage)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.tint)
                    Spacer()
                    Image(systemName: metric.trend.systemImage)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(metric.value)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                    Text(metric.title)
                        .font(.callout.weight(.medium))
                    Text(metric.caption)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }
}
