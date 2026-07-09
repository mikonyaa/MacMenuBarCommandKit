import SwiftUI

public struct MainDashboardView: View {
    @ObservedObject private var commandStore: CommandStore
    @ObservedObject private var dashboardStore: DashboardStore
    private let onCommand: (CommandItem) -> Void
    @State private var selectedSection: DashboardSection? = .today

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
            detailContent
        }
        .navigationTitle("CommandKit")
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(DashboardSection.allCases) { section in
                sidebarButton(section)
            }
            Spacer(minLength: 0)
        }
        .padding(.top, 54)
        .padding(.horizontal, 12)
        .padding(.bottom, 14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(.bar)
        .navigationTitle("CommandKit")
        .navigationSplitViewColumnWidth(min: 220, ideal: 230, max: 280)
    }

    private func sidebarButton(_ section: DashboardSection) -> some View {
        let isSelected = currentSection == section

        return Button {
            selectedSection = section
        } label: {
            Label(section.title, systemImage: section.systemImage)
                .font(.body.weight(isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? .white : .primary)
                .lineLimit(1)
                .frame(maxWidth: .infinity, minHeight: 36, alignment: .leading)
                .padding(.horizontal, 12)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background {
            if isSelected {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.accentColor.gradient)
            }
        }
        .help(section.subtitle)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    private var detailContent: some View {
        GrabScrollView {
            VStack(alignment: .leading, spacing: 20) {
                switch currentSection {
                case .today:
                    hero
                    metricsGrid
                    quickActions(limit: nil)
                    recentActivity(limit: 4)
                case .actions:
                    pageHeader(
                        title: "Quick Actions",
                        subtitle: "Search, run, and replace command handlers without rewriting the interface."
                    )
                    commandSearch
                    quickActions(limit: nil)
                case .recent:
                    pageHeader(
                        title: "Recent Commands",
                        subtitle: "A live audit trail that proves every action changed local state."
                    )
                    recentCommands
                    recentActivity(limit: nil)
                case .status:
                    pageHeader(
                        title: "System Status",
                        subtitle: "Template-ready health cards for menu bar utilities and local-first tools."
                    )
                    systemStatus
                    metricsGrid
                }
            }
            .padding(28)
            .frame(maxWidth: 1040, alignment: .leading)
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

    private var currentSection: DashboardSection {
        selectedSection ?? .today
    }

    private var hero: some View {
        AppCard {
            HStack(alignment: .center, spacing: 18) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Command Center")
                        .font(.largeTitle.bold())
                    Text("A production-ready menu bar shell for quick commands, local state, settings, and keyboard-first macOS workflows.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack {
                        StatusBadge(commandStore.isFocusModeEnabled ? "Focus active" : "Ready", color: commandStore.isFocusModeEnabled ? .indigo : .green)
                        StatusBadge("Local data", systemImage: "externaldrive", color: .blue)
                        if commandStore.hasActionSummary {
                            StatusBadge(commandStore.lastActionSummary, systemImage: "checkmark.circle", color: .gray)
                        }
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

    private func pageHeader(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.largeTitle.bold())
            Text(subtitle)
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 4)
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

    private var commandSearch: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Filter commands", text: $commandStore.query)
                .textFieldStyle(.plain)
            if !commandStore.query.isEmpty {
                Button {
                    commandStore.query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .help("Clear search")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(.separator.opacity(0.35), lineWidth: 1)
        }
    }

    private func quickActions(limit: Int?) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader("Quick Actions", subtitle: "Commands are metadata first, handlers second.")
            AppCard {
                let commands = Array(commandStore.filteredCommands.prefix(limit ?? Int.max))
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 280), spacing: 10)], spacing: 10) {
                    ForEach(commands) { command in
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
    private func recentActivity(limit: Int?) -> some View {
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
                        ForEach(Array(dashboardStore.activities.prefix(limit ?? Int.max))) { activity in
                            activityRow(activity)
                        }
                    }
                }
            }
        }
    }

    private var recentCommands: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader("Command History", subtitle: "The newest command stays on top.")
            if commandStore.recentCommands.isEmpty {
                EmptyStateView(
                    title: "No commands run yet",
                    message: "Run a quick action or press Command-K to start.",
                    systemImage: "clock.arrow.circlepath"
                )
            } else {
                AppCard {
                    VStack(spacing: 10) {
                        ForEach(commandStore.recentCommands) { command in
                            CommandRow(command: command)
                        }
                    }
                }
            }
        }
    }

    private var systemStatus: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: 14)], spacing: 14) {
            statusCard(
                title: "Menu Bar Extra",
                value: "Window style",
                caption: "Compact dashboard is active",
                systemImage: "menubar.rectangle",
                color: .blue
            )
            statusCard(
                title: "Settings Scene",
                value: "Native",
                caption: "Open with Command-comma",
                systemImage: "gearshape.2",
                color: .indigo
            )
            statusCard(
                title: "Data Mode",
                value: "Local",
                caption: "No backend or analytics",
                systemImage: "externaldrive",
                color: .green
            )
            statusCard(
                title: "Command Routing",
                value: "\(commandStore.registry.commands.count) ready",
                caption: "Metadata and handlers are separated",
                systemImage: "switch.2",
                color: .orange
            )
        }
    }

    private func statusCard(
        title: String,
        value: String,
        caption: String,
        systemImage: String,
        color: Color
    ) -> some View {
        AppCard {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: systemImage)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(color)
                    .frame(width: 32, height: 32)
                    .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                VStack(alignment: .leading, spacing: 3) {
                    Text(value)
                        .font(.title3.bold())
                    Text(title)
                        .font(.callout.weight(.medium))
                    Text(caption)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
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

private enum DashboardSection: String, CaseIterable, Identifiable, Hashable {
    case today
    case actions
    case recent
    case status

    var id: String { rawValue }

    var title: String {
        switch self {
        case .today:
            "Today"
        case .actions:
            "Quick Actions"
        case .recent:
            "Recent Commands"
        case .status:
            "System Status"
        }
    }

    var subtitle: String {
        switch self {
        case .today:
            "Overview, metrics, and recent activity"
        case .actions:
            "Search and run available commands"
        case .recent:
            "Review command history and activity"
        case .status:
            "Inspect local template status"
        }
    }

    var systemImage: String {
        switch self {
        case .today:
            "sun.max"
        case .actions:
            "bolt"
        case .recent:
            "clock.arrow.circlepath"
        case .status:
            "chart.xyaxis.line"
        }
    }
}
