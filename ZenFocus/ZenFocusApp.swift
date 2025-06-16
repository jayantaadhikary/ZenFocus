import SwiftUI
import SwiftData

@main
struct ZenFocusApp: App {
    @State private var userSettings: UserSettings?
    
    var body: some Scene {
        WindowGroup {
            AppEntryView(userSettings: $userSettings)
        }
        .modelContainer(for: [FocusSession.self, UserSettings.self, FocusTask.self])
    }
}

// MARK: - Entry View Wrapper for Async Loading
struct AppEntryView: View {
    @Environment(\.modelContext) private var context
    @Binding var userSettings: UserSettings?

    var body: some View {
        Group {
            if let settings = userSettings {
                ContentView()
                    .preferredColorScheme(colorScheme(for: settings.theme))
            } else {
                ProgressView("Loading Settings...")
                    .task {
                        await loadSettings()
                    }
            }
        }
    }

    func colorScheme(for theme: AppTheme) -> ColorScheme? {
        switch theme {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    func loadSettings() async {
        do {
            var descriptor = FetchDescriptor<UserSettings>()
            descriptor.fetchLimit = 1
            
            if let setting = try context.fetch(descriptor).first {
                userSettings = setting
            } else {
                let defaultSetting = UserSettings()
                context.insert(defaultSetting)
                try context.save()
                userSettings = defaultSetting
            }
        } catch {
            print("Failed to load settings: \(error)")
        }
    }

}
