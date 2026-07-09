import SwiftUI

public struct MainDashboardView: View {
    @ObservedObject private var commandStore: CommandStore
    @ObservedObject private var dashboardStore: DashboardStore
    private let onCommand: (CommandItem) -> Void

    public init(
        commandStore: CommandStore,
        dashboardStore: DashboardStore,
        onCommand: @escaping (CommandItem) -> Void
    ) {
        self.commandStore = commandStore
        self.dashboardStore = dashboardStore
        self.onCommand = onCommand
    }

    public var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            dashboard
        }
        .navigationTitle("CommandKit")
    }

    private var sidebar: some View {
        List(selection: .constant("today")) {
            Label("Today", systemImage: "sun.max")
                .tag("today")
            Label("Quick Actions", systemImage: "bolt")
                .tag("actions")
            Label("Recent Commands", systemImage: "clock.arrow.circlepath")
                .tag("recent")
            Label("System Status", systemImage: "chart.xyaxis.line")
                .tag("status")
        }
        .listStyle(.sidebar)
        .navigationTitle("CommandKit")
    }

    private var dashboard: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                hero
                metricsGrid
                quickActions
                recentActivity
            }
            .padding(28)
            .frame(maxWidth: 980, alignment: .leading)
        }
        .background(.background)
        .toolbar {
            ToolbarItemGroup {
                Button {
                    commandStore.presentPalette()
                } label: {
                    Label("Command Palette", systemImage: "command")
                }
                .keyboardShortcut("k", modifiers: .command)
                .help("Open Command Palette")
            }
        }
    }

    private var hero: some View {
        AppCard {
            HStack(alignment: .center, spacing: 18) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("AI Command Center")
                        .font(.largeTitle.bold())
                    Text("A production-ready menu bar shell for quick commands, local state, settings, and keyboard-first macOS workflows.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack {
                        StatusBadge(commandStore.isFocusModeEnabled ? "Focus active" : "Ready", color: commandStore.isFocusModeEnabled ? .indigo : .green)
                        StatusBadge("Local data", systemImage: "externaldrive", color: .blue)
                    }
                }
                Spacer()
                Button {
                    commandStore.presentPalette()
                } label: {
                    Label("Run Command", systemImage: "sparkles")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
    }

    private var metricsGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader("Today", subtitle: "Replace these deterministic cards with your product metrics.")
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 180), spacing: 14)], spacing: 14) {
                ForEach(dashboardStore.metrics) { metric in
                    MetricCardView(metric: metric)
                }
            }
        }
    }

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader("Quick Actions", subtitle: "Commands are metadata first, handlers second.")
            AppCard {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 280), spacing: 10)], spacing: 10) {
                    ForEach(commandStore.registry.commands) { command in
                        Button {
                            onCommand(command)
                        } label: {
                            CommandRow(command: command)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var recentActivity: some View {
        switch dashboardStore.state {
        case .loading:
            AppCard {
                HStack {
                    ProgressView()
                    Text("Loading dashboard")
                }
            }
        case .empty:
            EmptyStateView(title: "No recent activity", message: "Enable demo data or run a command.", systemImage: "tray")
        case .error(let message):
            EmptyStateView(title: "Dashboard error", message: message, systemImage: "exclamationmark.triangle")
        case .loaded:
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader("Recent Commands", subtitle: "A compact activity feed for menu bar utilities.")
                AppCard {
                    VStack(spacing: 10) {
                        ForEach(dashboardStore.activities) { activity in
                            activityRow(activity)
                        }
                    }
                }
            }
        }
    }

    private func activityRow(_ activity: ActivityItem) -> some View {
        HStack(spacing: 12) {
            Image(systemName: activity.systemImage)
                .font(.callout.weight(.semibold))
                .foregroundStyle(activity.tone.color)
                .frame(width: 28, height: 28)
                .background(activity.tone.color.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(activity.title)
                    .font(.callout.weight(.semibold))
                Text(activity.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(activity.timestamp)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }
}
