# RFC 005: Audio Notifications

## Status
- Status: Proposed
- Created: 2024-02-08
- Target Version: 1.1.0

## Overview
This RFC proposes implementing a comprehensive audio notification system for the TaskTimer app, providing audible feedback for timer completion and other important events.

## Motivation
Users need audio feedback when timers complete, especially when the app is in the background or the device is locked. This feature will enhance the app's utility and user experience.

## Technical Details

### 1. Audio System
#### 1.1 Audio Manager
```swift
class AudioManager: ObservableObject {
    static let shared = AudioManager()
    
    private var audioPlayers: [UUID: AVAudioPlayer] = [:]
    private let soundsDirectory = "Sounds"
    
    enum Sound: String {
        case timerComplete = "timer_complete"
        case timerStart = "timer_start"
        case buttonTap = "button_tap"
        case error = "error"
        
        var filename: String {
            return "\(rawValue).wav"
        }
    }
    
    func playSound(_ sound: Sound, volume: Float = 1.0) {
        guard let url = Bundle.main.url(forResource: sound.rawValue, withExtension: "wav", subdirectory: soundsDirectory) else {
            print("Sound file not found: \(sound.filename)")
            return
        }
        
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = volume
            player.play()
            
            // Store player reference to prevent deallocation
            let playerId = UUID()
            audioPlayers[playerId] = player
            
            // Remove reference after playback
            DispatchQueue.main.asyncAfter(deadline: .now() + player.duration) { [weak self] in
                self?.audioPlayers.removeValue(forKey: playerId)
            }
        } catch {
            print("Failed to play sound: \(error.localizedDescription)")
        }
    }
}
```

### 2. Notification System
#### 2.1 Notification Manager
```swift
class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    private let notificationCenter = UNUserNotificationCenter.current()
    
    func requestPermissions() {
        notificationCenter.requestAuthorization(options: [.alert, .sound]) { granted, error in
            if granted {
                print("Notification permissions granted")
            } else if let error = error {
                print("Failed to request notification permissions: \(error.localizedDescription)")
            }
        }
    }
    
    func scheduleTimerCompletionNotification(for task: Task) {
        let content = UNMutableNotificationContent()
        content.title = "Timer Complete"
        content.body = "\(task.title) has finished"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: task.remainingTime,
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: task.id.uuidString,
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request)
    }
    
    func cancelNotification(for taskId: UUID) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [taskId.uuidString])
    }
}
```

### 3. Sound Assets
#### 3.1 Sound File Structure
```
Sounds/
├── timer_complete.wav
├── timer_start.wav
├── button_tap.wav
└── error.wav
```

### 4. Integration with Timer System
```swift
extension Task {
    func handleCompletion() {
        if SettingsManager.shared.settings.timerPreferences.soundEnabled {
            AudioManager.shared.playSound(
                .timerComplete,
                volume: Float(SettingsManager.shared.settings.notificationSettings.soundVolume)
            )
        }
        
        if SettingsManager.shared.settings.notificationSettings.showNotifications {
            NotificationManager.shared.scheduleTimerCompletionNotification(for: self)
        }
        
        if SettingsManager.shared.settings.timerPreferences.hapticFeedback {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
}
```

### 5. Audio Session Management
```swift
extension AudioManager {
    func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .ambient,
                mode: .default,
                options: [.mixWithOthers]
            )
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to configure audio session: \(error.localizedDescription)")
        }
    }
    
    func cleanupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            print("Failed to deactivate audio session: \(error.localizedDescription)")
        }
    }
}
```

### 6. Custom Sound Support
```swift
extension AudioManager {
    func importCustomSound(from url: URL) throws -> String {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let soundsDirectory = documentsDirectory.appendingPathComponent("CustomSounds")
        
        try FileManager.default.createDirectory(
            at: soundsDirectory,
            withIntermediateDirectories: true
        )
        
        let filename = url.lastPathComponent
        let destination = soundsDirectory.appendingPathComponent(filename)
        
        try FileManager.default.copyItem(at: url, to: destination)
        return filename
    }
    
    func loadCustomSound(_ filename: String) -> AVAudioPlayer? {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let soundsDirectory = documentsDirectory.appendingPathComponent("CustomSounds")
        let soundURL = soundsDirectory.appendingPathComponent(filename)
        
        return try? AVAudioPlayer(contentsOf: soundURL)
    }
}
```

## Implementation Steps
1. Add audio frameworks and capabilities
2. Create sound assets
3. Implement AudioManager
4. Implement NotificationManager
5. Add custom sound support
6. Integrate with timer system
7. Add settings integration
8. Test audio behavior

## Migration Strategy
- No migration needed for existing app data
- Add audio assets to app bundle
- Create custom sounds directory

## Testing Requirements
1. Audio playback:
   - Different system states
   - Multiple simultaneous sounds
   - Custom sounds
2. Notification behavior:
   - Background state
   - Lock screen
   - Do Not Disturb mode
3. Performance:
   - Memory usage
   - Battery impact
   - Resource cleanup

## Security Considerations
- Audio permission handling
- Notification permission handling
- Custom sound file validation
- Resource limits for custom sounds

## Timeline
- Development: 3 days
- Testing: 2 days
- Documentation: 1 day
- Total: 1 week

## Future Considerations
- Additional sound effects
- Sound themes
- Advanced audio mixing
- Voice notifications 