# RFC 004: Settings and Preferences

## Status
- Status: Proposed
- Created: 2024-02-08
- Target Version: 1.1.0

## Overview
This RFC proposes implementing a comprehensive settings and preferences system for the TaskTimer app, allowing users to customize their experience and manage app-wide configurations.

## Motivation
Users need the ability to customize their experience and set preferences for timer behavior, appearance, and notifications. A centralized settings system will improve user experience and app flexibility.

## Technical Details

### 1. Settings Model
#### 1.1 Settings Structure
```swift
struct AppSettings: Codable {
    var appearance: AppearanceSettings
    var timerPreferences: TimerPreferences
    var notificationSettings: NotificationSettings
    var defaultConfigurations: DefaultConfigurations
    
    struct AppearanceSettings: Codable {
        var useRandomColors: Bool
        var colorScheme: ColorScheme
        var cardStyle: CardStyle
        var fontSizeScale: Double
        
        enum ColorScheme: String, Codable {
            case system
            case light
            case dark
        }
        
        enum CardStyle: String, Codable {
            case minimal
            case modern
            case classic
        }
    }
    
    struct TimerPreferences: Codable {
        var defaultCountdownDuration: TimeInterval
        var soundEnabled: Bool
        var hapticFeedback: Bool
        var backgroundRefreshEnabled: Bool
        var displayFormat: TimeDisplayFormat
        
        enum TimeDisplayFormat: String, Codable {
            case digital    // 00:00
            case natural   // 1h 30m
            case decimal   // 1.5h
        }
    }
    
    struct NotificationSettings: Codable {
        var timerCompletionSound: String
        var soundVolume: Double
        var showNotifications: Bool
        var groupNotifications: Bool
        var notificationStyle: NotificationStyle
        
        enum NotificationStyle: String, Codable {
            case banner
            case alert
            case none
        }
    }
    
    struct DefaultConfigurations: Codable {
        var defaultTimerType: TimerType
        var autoStartNextTimer: Bool
        var keepScreenOn: Bool
        var saveRecentConfigs: Bool
        var maxRecentConfigs: Int
    }
}
```

### 2. Settings Management
#### 2.1 Settings Manager
```swift
class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    
    @Published private(set) var settings: AppSettings {
        didSet {
            saveSettings()
        }
    }
    
    private let defaults = UserDefaults.standard
    private let settingsKey = "com.tasktimer.settings"
    
    init() {
        if let data = defaults.data(forKey: settingsKey),
           let decoded = try? JSONDecoder().decode(AppSettings.self, from: data) {
            self.settings = decoded
        } else {
            self.settings = AppSettings.defaultSettings()
        }
    }
    
    func updateSettings(_ update: (inout AppSettings) -> Void) {
        var newSettings = settings
        update(&newSettings)
        settings = newSettings
    }
    
    private func saveSettings() {
        if let encoded = try? JSONEncoder().encode(settings) {
            defaults.set(encoded, forKey: settingsKey)
        }
    }
}
```

### 3. Settings UI
#### 3.1 Main Settings View
```swift
struct SettingsView: View {
    @StateObject private var settingsManager = SettingsManager.shared
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            List {
                Section("Appearance") {
                    NavigationLink("Visual Style") {
                        AppearanceSettingsView()
                    }
                }
                
                Section("Timer") {
                    NavigationLink("Timer Preferences") {
                        TimerSettingsView()
                    }
                }
                
                Section("Notifications") {
                    NavigationLink("Notification Settings") {
                        NotificationSettingsView()
                    }
                }
                
                Section("Defaults") {
                    NavigationLink("Default Configurations") {
                        DefaultConfigurationsView()
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}
```

#### 3.2 Appearance Settings View
```swift
struct AppearanceSettingsView: View {
    @StateObject private var settingsManager = SettingsManager.shared
    
    var body: some View {
        Form {
            Toggle("Use Random Colors", isOn: binding(for: \.appearance.useRandomColors))
            
            Picker("Color Scheme", selection: binding(for: \.appearance.colorScheme)) {
                Text("System").tag(AppSettings.AppearanceSettings.ColorScheme.system)
                Text("Light").tag(AppSettings.AppearanceSettings.ColorScheme.light)
                Text("Dark").tag(AppSettings.AppearanceSettings.ColorScheme.dark)
            }
            
            Picker("Card Style", selection: binding(for: \.appearance.cardStyle)) {
                Text("Minimal").tag(AppSettings.AppearanceSettings.CardStyle.minimal)
                Text("Modern").tag(AppSettings.AppearanceSettings.CardStyle.modern)
                Text("Classic").tag(AppSettings.AppearanceSettings.CardStyle.classic)
            }
            
            Slider(
                value: binding(for: \.appearance.fontSizeScale),
                in: 0.8...1.2,
                step: 0.1
            ) {
                Text("Font Size")
            }
        }
        .navigationTitle("Appearance")
    }
    
    private func binding<T>(for keyPath: WritableKeyPath<AppSettings, T>) -> Binding<T> {
        Binding(
            get: { self.settingsManager.settings[keyPath: keyPath] },
            set: { newValue in
                self.settingsManager.updateSettings { settings in
                    settings[keyPath: keyPath] = newValue
                }
            }
        )
    }
}
```

### 4. Settings Application
```swift
extension View {
    func applySettings(_ settings: AppSettings) -> some View {
        self.modifier(SettingsModifier(settings: settings))
    }
}

struct SettingsModifier: ViewModifier {
    let settings: AppSettings
    
    func body(content: Content) -> some View {
        content
            .environment(\.colorScheme, colorScheme)
            .environment(\.sizeCategory, sizeCategory)
            .preferredColorScheme(colorScheme)
    }
    
    private var colorScheme: ColorScheme {
        switch settings.appearance.colorScheme {
        case .system: return .current
        case .light: return .light
        case .dark: return .dark
        }
    }
    
    private var sizeCategory: ContentSizeCategory {
        let scale = settings.appearance.fontSizeScale
        return ContentSizeCategory.scaled(by: scale)
    }
}
```

## Implementation Steps
1. Create settings data models
2. Implement settings manager
3. Design and implement settings UI
4. Add settings persistence
5. Create settings application system
6. Implement settings migration
7. Add default values
8. Create documentation

## Migration Strategy
- Create default settings for new installations
- Migrate existing preferences to new format
- Preserve user customizations during updates

## Testing Requirements
1. Settings persistence:
   - Save/load functionality
   - Migration handling
   - Default values
2. UI testing:
   - All settings screens
   - Input validation
   - Real-time updates
3. Performance:
   - Settings load time
   - UI responsiveness
   - Memory usage

## Security Considerations
- Secure storage of sensitive settings
- Input validation
- Settings file integrity

## Timeline
- Development: 4 days
- Testing: 2 days
- Documentation: 1 day
- Total: 1 week

## Future Considerations
- Cloud sync for settings
- Profile-based settings
- Import/export settings
- Advanced customization options 