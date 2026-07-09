import SwiftUI

public struct MenuBarDashboard: View {
    @ObservedObject private var commandStore: CommandStore
    @ObservedObject private var dashboardStore: DashboardStore
    @ObservedObject private var settingsStore: SettingsStore
    private let onCommand: (CommandItem) -> Void
    private let openMainWindow: () -> Void
    private let openSettings: () -> Void
    private let quit: () -> Void

    public init(
        commandStore: CommandStore,
        dashboardStore: DashboardStore,
        settingsStore: SettingsStore,
        onCommand: @escaping (CommandItem) -> Void,
        openMainWindow: @escaping () -> Void,
        openSettings: @escaping () -> Void,
        quit: @escaping () -> Void
    ) {
        self.commandStore = commandStore
        self.dashboardStore = dashboardStore
        self.settingsStore = settingsStore
        self.onCommand = onCommand
        self.openMainWindow = openMainWindow
        self.openSettings = openSettings
        self.quit = quit
    }

    public var body: some View {
        VStack(spacing: 14) {
            header
            searchField
            GrabScrollView(showsIndicators: true) {
                content
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: settingsStore.settings.menuBarPresentation == .compact ? 340 : 430)
            footer
        }
        .padding(16)
        .frame(
            width: settingsStore.settings.menuBarPresentation == .compact ? 340 : 390,
            height: settingsStore.settings.menuBarPresentation == .compact ? 520 : 620
        )
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: "command.circle")
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(.blue.gradient, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text("CommandKit")
                    .font(.headline)
                Text(commandStore.hasActionSummary ? commandStore.lastActionSummary : "Local command router")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            StatusBadge(commandStore.isFocusModeEnabled ? "Focus" : "Ready", color: commandStore.isFocusModeEnabled ? .indigo : .green)
        }
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Run a command", text: $commandStore.query)
                .textFieldStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(.separator.opacity(0.45), lineWidth: 1)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch dashboardStore.state {
        case .loading:
            AppCard {
                HStack(spacing: 10) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Loading local demo data")
                        .font(.callout)
                }
            }
        case .empty:
            EmptyStateView(
                title: "No activity yet",
                message: "Run a command to fill the menu bar dashboard.",
                systemImage: "sparkles.rectangle.stack"
            )
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        case .error(let message):
            EmptyStateView(title: "Something needs attention", message: message, systemImage: "exclamationmark.triangle")
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        case .loaded:
            loadedContent
        }
    }

    private var loadedContent: some View {
        VStack(spacing: 12) {
            SectionHeader("Quick Commands", subtitle: "Local actions you can replace")
            VStack(spacing: 2) {
                ForEach(Array(commandStore.filteredCommands.prefix(4))) { command in
                    Button {
                        onCommand(command)
                    } label: {
                        CommandRow(command: command)
                    }
                    .buttonStyle(.plain)
                }
            }

            if let firstMetric = dashboardStore.metrics.first {
                MetricCardView(metric: firstMetric)
            }

            if !dashboardStore.activities.isEmpty {
                SectionHeader(
                    "Activity",
                    subtitle: commandStore.hasActionSummary ? commandStore.lastActionSummary : "Latest local events"
                )
                VStack(spacing: 2) {
                    ForEach(Array(dashboardStore.activities.prefix(3))) { activity in
                        HStack(spacing: 10) {
                            Image(systemName: activity.systemImage)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(activity.tone.color)
                                .frame(width: 24, height: 24)
                                .background(activity.tone.color.opacity(0.12), in: RoundedRectangle(cornerRadius: 7, style: .continuous))
                            VStack(alignment: .leading, spacing: 1) {
                                Text(activity.title)
                                    .font(.caption.weight(.semibold))
                                    .lineLimit(1)
                                Text(activity.subtitle)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 7)
                    }
                }
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(.separator.opacity(0.35), lineWidth: 1)
                }
            }
        }
    }

    private var footer: some View {
        HStack(spacing: 8) {
            Button(action: openMainWindow) {
                Label("Open Window", systemImage: "macwindow")
            }
            Button(action: openSettings) {
                Label("Settings", systemImage: "gearshape")
            }
            Spacer()
            Button(role: .destructive, action: quit) {
                Label("Quit", systemImage: "power")
            }
        }
        .controlSize(.small)
    }
}
