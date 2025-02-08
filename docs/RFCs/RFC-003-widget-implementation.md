# RFC 003: Widget Implementation

## Status
- Status: Proposed
- Created: 2024-02-08
- Target Version: 1.1.0

## Overview
This RFC proposes implementing widget support for the TaskTimer app, allowing users to view and control their timers directly from the iOS home screen and lock screen.

## Motivation
Users need quick access to their timers without opening the app. Widgets provide at-a-glance information and basic controls for active timers, enhancing the app's utility and user experience.

## Technical Details

### 1. Widget Configuration
#### 1.1 Widget Definition
```swift
struct TaskTimerWidget: Widget {
    private let supportedFamilies: [WidgetFamily] = [
        .systemSmall,
        .systemMedium,
        .accessoryCircular,
        .accessoryRectangular
    ]
    
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: "com.tasktimer.widget",
            provider: TimerProvider()
        ) { entry in
            TaskTimerWidgetView(entry: entry)
        }
        .configurationDisplayName("Task Timer")
        .description("View and control your active timers")
        .supportedFamilies(supportedFamilies)
    }
}
```

### 2. Widget Data Model
#### 2.1 Timeline Entry
```swift
struct TaskTimerEntry: TimelineEntry {
    let date: Date
    let activeTimers: [TimerWidgetData]
    let configuration: TaskTimerWidgetConfiguration
    
    struct TimerWidgetData: Codable {
        let id: UUID
        let title: String
        let remainingTime: TimeInterval
        let isRunning: Bool
        let type: TimerType
        let progress: Double
    }
}

struct TaskTimerWidgetConfiguration: Codable {
    var displayMode: DisplayMode
    var selectedTimerIds: [UUID]
    
    enum DisplayMode: String, Codable {
        case single
        case list
        case grid
    }
}
```

### 3. Timeline Provider
```swift
struct TimerProvider: TimelineProvider {
    func placeholder(in context: Context) -> TaskTimerEntry {
        TaskTimerEntry(
            date: Date(),
            activeTimers: [
                .init(id: UUID(), title: "Sample Timer", remainingTime: 300, isRunning: true, type: .countdown, progress: 0.5)
            ],
            configuration: .init(displayMode: .single, selectedTimerIds: [])
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (TaskTimerEntry) -> Void) {
        let entry = TaskTimerEntry(
            date: Date(),
            activeTimers: TimerManager.shared.getActiveTimersData(),
            configuration: loadConfiguration()
        )
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<TaskTimerEntry>) -> Void) {
        var entries: [TaskTimerEntry] = []
        let currentDate = Date()
        let updateInterval: TimeInterval = 60 // Update every minute
        
        // Create timeline entries for the next hour
        for offset in stride(from: 0, to: 3600, by: updateInterval) {
            let entryDate = currentDate.addingTimeInterval(offset)
            let entry = TaskTimerEntry(
                date: entryDate,
                activeTimers: TimerManager.shared.getActiveTimersData(),
                configuration: loadConfiguration()
            )
            entries.append(entry)
        }
        
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}
```

### 4. Widget Views
#### 4.1 Small Widget
```swift
struct SmallWidgetView: View {
    let entry: TaskTimerEntry
    
    var body: some View {
        if let timer = entry.activeTimers.first {
            VStack(spacing: 4) {
                Text(timer.title)
                    .font(.caption)
                    .lineLimit(1)
                
                Text(formatTime(timer.remainingTime))
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                
                CircularProgressView(progress: timer.progress)
                    .frame(width: 40, height: 40)
            }
            .padding()
        } else {
            Text("No Active Timers")
                .font(.caption)
        }
    }
}
```

#### 4.2 Medium Widget
```swift
struct MediumWidgetView: View {
    let entry: TaskTimerEntry
    
    var body: some View {
        HStack {
            ForEach(entry.activeTimers.prefix(3), id: \.id) { timer in
                TimerCell(timer: timer)
            }
        }
        .padding()
    }
}

struct TimerCell: View {
    let timer: TaskTimerEntry.TimerWidgetData
    
    var body: some View {
        VStack(spacing: 4) {
            Text(timer.title)
                .font(.caption)
                .lineLimit(1)
            
            Text(formatTime(timer.remainingTime))
                .font(.system(size: 18, weight: .bold, design: .rounded))
            
            ProgressView(value: timer.progress)
                .frame(height: 3)
        }
        .padding(8)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(8)
    }
}
```

### 5. Widget Actions
```swift
struct WidgetActions {
    static func handleTap(timer: TaskTimerEntry.TimerWidgetData) {
        let url = URL(string: "tasktimer://timer/\(timer.id)")!
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    static func toggleTimer(_ timer: TaskTimerEntry.TimerWidgetData) {
        let url = URL(string: "tasktimer://timer/\(timer.id)/toggle")!
        WidgetCenter.shared.reloadAllTimelines()
    }
}
```

## Implementation Steps
1. Create WidgetKit extension target
2. Implement widget data models
3. Create timeline provider
4. Design and implement widget views
5. Add widget configuration options
6. Implement deep linking
7. Add widget actions
8. Test on different device sizes

## Migration Strategy
- No migration needed for existing app data
- Add widget capability to app target
- Update app URL scheme handling

## Testing Requirements
1. Widget functionality:
   - Data updates
   - User interactions
   - Deep linking
2. Performance:
   - Memory usage
   - Battery impact
   - Update frequency
3. Visual testing:
   - All widget sizes
   - Dark/light mode
   - Dynamic type

## Security Considerations
- Secure data sharing between app and widget
- URL scheme validation
- Resource usage optimization

## Timeline
- Development: 1 week
- Testing: 3 days
- Documentation: 1 day
- Total: 1.5 weeks

## Future Considerations
- Additional widget sizes
- Interactive complications
- Widget customization options
- Multiple widget instances 