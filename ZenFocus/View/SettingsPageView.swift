import SwiftUI
import SwiftData


extension AppTheme {
    var displayName: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
}

struct SettingsPageView: View {
    @Query private var settings: [UserSettings]
    @Environment(\.modelContext) private var context
    
    
    
    var body: some View {
        NavigationStack {
            ScrollView {
                if let setting = settings.first {
                    SettingsForm(setting: setting)
                        .padding()
                    
                } else {
                    VStack(spacing: 16) {
                        Text("No settings found.")
                        Button("Initialize Settings") {
                            let newSetting = UserSettings()
                            context.insert(newSetting)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Settings")
        }
    }
}


struct SettingsForm: View {
    @Bindable var setting: UserSettings
    @State private var showManageTasksSheet: Bool = false
    @State private var showAboutSheet = false
    @State private var showProSheet = false


    
    func openEmail() {
        guard let url = URL(string: "mailto:jayadky@yahoo.com?subject=ZenFocus Feedback") else { return }
        UIApplication.shared.open(url)
    }
    
    var body: some View {
        VStack(spacing: 32) {
            // MARK: - Focus Settings
            GroupBox(label: Label("Focus Settings", systemImage: "timer")) {
                VStack(spacing: 10) {
                    HStack {
                        Text("Default Duration")
                        Spacer()
                        Stepper(value: $setting.defaultFocusDuration, in: 300...7200, step: 300) {
                            Text("\(setting.defaultFocusDuration / 60) min")
                                .bold()
                        }
                    }
                    
                    HStack {
                        Text("Session Target")
                        Spacer()
                        Stepper(value: $setting.dailyTargetSessions, in: 1...10) {
                            Text("\(setting.dailyTargetSessions)")
                                .bold()
                        }
                    }
                    
                    Button {
                        showManageTasksSheet = true
                    } label: {
                        Label("Manage Focus Tasks", systemImage: "checklist")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.vertical, 8)
                    .sheet(isPresented: $showManageTasksSheet) {
                        ManageTasksSheet()
                    }
                }
                .padding(.top, 4)
            }
            
            // MARK: - General Settings
            GroupBox(label: Label("Preferences", systemImage: "gear")){
                
                VStack (spacing: 1) {
                    HStack {
                        Label("Appearance", systemImage: "circle.lefthalf.filled")
                            .labelStyle(.titleAndIcon)
                        Spacer()
                        Picker("", selection: $setting.theme) {
                            ForEach(AppTheme.allCases, id: \.self) { theme in
                                Text(theme.displayName)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    .padding(.vertical, 4)
                    
                    SettingsRow(label: "App Icons", icon: "app"){
                        
                    }

                    
                    SettingsRow(label: "Upgrade to ZenFocus Pro", icon: "star.fill") {
                        showProSheet = true
                    }
                    .sheet(isPresented: $showProSheet) {
                        UpgradeProSheet()
                            .presentationDragIndicator(.visible)
                    }
                }
            }
            
            // MARK: - Support Settings
            GroupBox(label: Label("Support & Info", systemImage: "info.circle")) {
                VStack(spacing: 1) {
                    SettingsRow(label: "About ZenFocus", icon: "info.circle") {
                        showAboutSheet = true
                    }
                    .sheet(isPresented: $showAboutSheet) {
                        AboutSheet()
                            .presentationDetents([.medium, .large])
                    }
                    
                    if let url = URL(string: "https://zenfocus.app") {
                        ShareLink(item: url) {
                            HStack {
                                Label("Share ZenFocus", systemImage: "square.and.arrow.up")
                                    .labelStyle(.titleAndIcon)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.gray)
                            }
                            .padding(.vertical)
                        }
                        .foregroundStyle(.primary)
                    }
                    
                    SettingsRow(label: "Contact Developer", icon: "envelope") {
                        openEmail()
                    }
                    
                    
                    
                    HStack {
                        Spacer()
                        Text("Version 1.0.0")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .padding(.top, 12)
                }
                .padding(.vertical, 4)
            }
        }
    }
}


#Preview {
    let model = UserSettings(defaultFocusDuration: 1500, dailyTargetSessions: 5)
    let container = try! ModelContainer(for: UserSettings.self, configurations: .init(isStoredInMemoryOnly: true))
    let context = ModelContext(container)
    context.insert(model)
    
    return SettingsPageView()
        .modelContainer(container)
}
