# RFC 001: Background Timer Operations and State Management

## Status
- Status: Proposed
- Created: 2024-02-08
- Target Version: 1.1.0

## Overview
This RFC proposes implementing robust background timer functionality and state management to ensure timers continue running when the app is in the background and maintain accuracy across state transitions.

## Motivation
Currently, timers stop when the app enters the background state, which limits the app's utility. Users expect their timers to continue running even when the app is not in the foreground.

## Technical Details

### 1. Background Task Registration
```swift
// In TaskTimerApp.swift
@main
struct TaskTimerApp: App {
    init() {
        registerBackgroundTasks()
    }
    
    func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "com.tasktimer.timer-update",
            using: nil
        ) { task in
            self.handleTimerUpdate(task: task as! BGProcessingTask)
        }
    }
}
```

### 2. Timer State Management
#### 2.1 Enhanced Timer Model
```swift
struct TimerState: Codable {
    var startTime: Date
    var pausedTime: TimeInterval
    var isRunning: Bool
    var backgroundEntryTime: Date?
    
    mutating func enterBackground() {
        backgroundEntryTime = Date()
    }
    
    mutating func exitBackground() {
        guard let entryTime = backgroundEntryTime else { return }
        let timeInBackground = Date().timeIntervalSince(entryTime)
        if isRunning {
            startTime = startTime.addingTimeInterval(timeInBackground)
        }
        backgroundEntryTime = nil
    }
}
```

#### 2.2 Background State Handling
```swift
class TimerManager: ObservableObject {
    @Published private(set) var timers: [UUID: TimerState] = [:]
    
    func handleBackgroundTransition() {
        for (_, timer) in timers {
            timer.enterBackground()
        }
        saveState()
    }
    
    func handleForegroundTransition() {
        loadState()
        for (_, timer) in timers {
            timer.exitBackground()
        }
    }
}
```

### 3. Timer Accuracy Improvements
#### 3.1 High-Precision Timer Implementation
```swift
class PrecisionTimer {
    private var displayLink: CADisplayLink?
    private var lastUpdate: CFTimeInterval
    
    init() {
        lastUpdate = CACurrentMediaTime()
        setupDisplayLink()
    }
    
    private func setupDisplayLink() {
        displayLink = CADisplayLink(target: self, selector: #selector(updateTimer))
        displayLink?.preferredFramesPerSecond = 30
        displayLink?.add(to: .current, forMode: .common)
    }
    
    @objc private func updateTimer() {
        let currentTime = CACurrentMediaTime()
        let delta = currentTime - lastUpdate
        lastUpdate = currentTime
        updateTimerState(delta)
    }
}
```

### 4. Resource Management
```swift
extension TimerManager {
    func cleanup() {
        // Stop all active timers
        for (id, _) in timers {
            stopTimer(id)
        }
        
        // Clear background tasks
        BGTaskScheduler.shared.cancelAllTaskRequests()
        
        // Save final state
        saveState()
    }
}
```

## Implementation Steps
1. Add BackgroundTasks framework to the project
2. Implement enhanced TimerState structure
3. Create TimerManager class
4. Add background task registration
5. Implement state persistence
6. Add high-precision timer implementation
7. Implement cleanup and resource management
8. Add background transition handlers
9. Test and validate timer accuracy

## Migration Strategy
- Existing timers will need to be converted to use the new TimerState structure
- Background capability will need to be added to Info.plist
- Users will need to grant background refresh permissions

## Testing Requirements
1. Timer accuracy in various states:
   - Foreground running
   - Background running
   - After state transitions
2. Resource usage monitoring
3. Battery impact assessment
4. State restoration verification

## Security Considerations
- Ensure proper cleanup of background tasks
- Implement proper state data encryption
- Handle permission denials gracefully

## Timeline
- Development: 2 weeks
- Testing: 1 week
- Documentation: 2 days
- Total: 3 weeks

## Future Considerations
- Support for multiple background update frequencies
- Battery optimization modes
- Integration with system time changes
- Handling of device restarts 