# TaskTimer - Product Requirements Document (PRD)

## 1. Product Overview
TaskTimer is a versatile task management and timing application designed for iOS/macOS that allows users to create, manage, and track multiple tasks with customizable timers. The app supports both stopwatch and countdown timer functionality for each task.

### 1.1 Purpose
To provide users with a flexible and intuitive interface for managing multiple timed tasks, whether they need to track time spent on activities (stopwatch) or set countdown timers for time-boxed tasks.

### 1.2 Target Users
- Professionals managing multiple time-sensitive tasks
- Students tracking study sessions
- Anyone needing to manage sequential timed activities
- Users requiring both time tracking and countdown functionality

## 2. Core Features

### 2.1 Task Management
- Create unlimited number of tasks
- Edit task titles inline
- Delete tasks with swipe-to-delete functionality
- Save and load task configurations
- Reorder tasks through drag-and-drop

### 2.2 Timer Functionality
#### Stopwatch Mode
- Start/pause/reset functionality
- Continuous time tracking
- Time display in MM:SS format
- Elapsed time persistence

#### Countdown Mode
- Customizable duration using wheel picker (minutes and seconds)
- Start/pause/reset functionality
- Visual countdown display
- Auto-reset to initial time after completion

### 2.3 Task Linking
- Connect countdown tasks to trigger subsequent tasks
- Automatic task chain execution
- Visual indication of linked tasks
- Ability to remove task links

### 2.4 Configuration Management
- Save multiple task configurations
- Name and organize saved configurations
- Load previously saved configurations
- Delete saved configurations

### 2.5 Visual Customization
- Optional random color generation for task cards
- Clean, modern card-based UI
- Visual feedback for timer states
- Consistent design language across the app

## 3. User Interface

### 3.1 Main Views
1. Tasks Tab
   - Scrollable list of task cards
   - Add task button
   - Save configuration button

2. Saved Tasks Tab
   - List of saved configurations
   - Configuration management options

3. Settings Tab
   - Visual customization options
   - App preferences

### 3.2 Task Card Components
- Title field with edit functionality
- Timer display/input area
- Control buttons (Start/Pause, Reset)
- Timer type selector (Stopwatch/Countdown)
- Task linking interface (for countdown mode)

### 3.3 Visual Interface Description
The app features a modern, card-based interface with a clean and minimalist design:

#### Main Task View
- Each task is presented as a distinct card with rounded corners
- Cards have a white background with subtle shadows for depth
- Task cards are arranged vertically in a scrollable list
- Floating action button ('+') at the bottom for adding new tasks

#### Task Card Layout
1. Header Section:
   - Left side: Task title with pencil icon for editing
   - Right side: Large timer display (MM:SS format)
   - Separator line between header and controls

2. Control Section:
   - Start/Pause button (green when starting, orange when pausing)
   - Reset button (red)
   - Timer type toggle (stopwatch/countdown icons)
   - All buttons have rounded corners and clear color coding

3. Connection Section (for countdown timers):
   - Appears below main card when in countdown mode
   - "Connect to" button with link icon
   - Shows connected task name when linked
   - Maintains card's rounded corner design

#### Visual States
- Running timers: Active state with highlighted controls
- Paused timers: Neutral state with standard button colors
- Completed tasks: Visual indication of completion
- Swipe-to-delete: Reveals red delete button with trash icon

#### Platform Adaptations
- iPad: Optimized layout with wider cards and more spacing
- iPhone: Compact layout with full-width cards
- Consistent visual language across device sizes
- Responsive design adjusting to screen orientation

## 4. Technical Requirements

### 4.1 Data Management
- Local storage using UserDefaults
- JSON encoding/decoding for configuration persistence
- Efficient state management using SwiftUI

### 4.2 Performance
- Smooth animations and transitions
- Accurate timer functionality
- Responsive UI even with multiple active timers
- Efficient memory management

### 4.3 Concurrent Timer Management
- Support for multiple simultaneous timers and stopwatches
- Each timer/stopwatch must maintain independent:
  - Time tracking
  - State management (running/paused)
  - Update cycles
- Timer accuracy must be maintained regardless of:
  - Number of active timers
  - UI interactions
  - Background operations
- System must handle resource allocation efficiently for concurrent timers

### 4.4 Safe State Management
- Implement safe deletion protocol for running timers:
  1. Mark timer for deletion and immediately stop updates
  2. Clear any references or links to the timer
  3. Remove from active timer pool
  4. Clean up associated resources
- Handle edge cases:
  - Deletion during active countdown
  - Removal while linked to other timers
  - Deletion during background operation
- Prevent array access errors:
  - Validate timer existence before updates
  - Use weak references where appropriate
  - Implement proper cleanup sequence
- Maintain data consistency:
  - Update linked timer states
  - Clean up observer patterns
  - Handle partial deletions

### 4.5 Platform Compatibility
- iOS/macOS support
- SwiftUI framework
- Modern Apple platform features

## 5. Background Operations and Notifications

### 5.1 Background Timer Functionality
- Timers must continue running when app is in background
- Accurate time tracking must be maintained when device is locked
- System must handle background execution limits appropriately
- Battery optimization considerations must be implemented

### 5.2 Widget Support
- Lock screen widget showing active timers
- Widget must display:
  - Task names
  - Remaining time for countdown timers
  - Elapsed time for stopwatch timers
  - Visual indicators for timer states (running/paused)
- Widget must update in real-time
- Support for multiple active timer display

### 5.3 Audio Notifications
- Play alarm sound when countdown timer reaches zero
- Alarm should sound even when device is locked
- User should be able to:
  - Choose from multiple alarm sounds
  - Adjust alarm volume
  - Enable/disable alarms globally
  - Set custom alarm sound per task
- Respect system sound settings and Do Not Disturb mode

### 5.4 Technical Implementation Requirements
- Use BackgroundTasks framework for timer management
- Implement WidgetKit for lock screen widget
- Utilize UserNotifications framework for audio alerts
- Handle system background execution constraints
- Implement proper state restoration after background mode

## 6. Success Metrics
1. User engagement with timer features
2. Configuration save/load frequency
3. Task completion rates
4. User retention
5. App stability and performance

## 7. Technical Architecture
- SwiftUI-based UI layer
- MVVM architecture
- Codable protocol for data persistence
- Native iOS frameworks and components

## 8. Implementation Details

### 8.1 Core Data Structures
```swift
struct Task: Identifiable, Codable {
    let id: UUID
    var title: String
    var elapsedTime: TimeInterval
    var timerRunning: Bool
    var timerType: TimerType
    var countdownTime: TimeInterval
    var initialCountdownTime: TimeInterval
    var backgroundColor: Color
    var buttonColor: Color
    var nextTaskId: UUID?
    var isCompleted: Bool
}

enum TimerType: Codable {
    case stopwatch
    case countdown
}

struct SavedConfig: Identifiable, Codable {
    let id: UUID
    let name: String
    let tasks: [Task]
}
```

### 8.2 Key Components
1. TaskCardView
   - Individual task display and management
   - Timer controls and state management
   - Task linking interface

2. ConfigurationManager
   - Configuration persistence
   - Save/load functionality
   - UserDefaults integration

3. ContentView
   - Main app navigation
   - Task list management
   - Configuration handling

### 8.3 User Interface Guidelines
1. Colors and Styling
   - System background colors for consistency
   - Optional random colors for visual variety
   - Clear visual hierarchy

2. Layout
   - Card-based design
   - Consistent spacing and padding
   - Responsive to different screen sizes

3. Interactions
   - Smooth animations for state changes
   - Intuitive swipe gestures
   - Clear visual feedback

## 9. Development Timeline

### Phase 1: Core Functionality
- Basic task management
- Timer implementation
- UI foundation

### Phase 2: Enhanced Features
- Task linking
- Configuration management
- Visual customization

### Phase 3: Polish and Optimization
- Performance optimization
- UI refinements
- Bug fixes and stability improvements

### Phase 4: Future Enhancements
- Cloud sync
- Additional features
- Platform-specific optimizations

## 10. Testing Requirements

### 10.1 Functional Testing
- Timer accuracy
- Task management operations
- Configuration persistence
- Task linking functionality

### 10.2 Performance Testing
- Multiple active timers
- Large configuration sets
- Memory usage
- Battery impact

### 10.3 User Interface Testing
- Different screen sizes
- Accessibility
- Dark/light mode
- Gesture handling

## 11. Maintenance and Support

### 11.1 Regular Updates
- Bug fixes
- Performance improvements
- Feature enhancements
- Platform compatibility

### 11.2 User Support
- Documentation
- FAQs
- Issue tracking
- Feature requests

## 12. Success Criteria

### 12.1 Technical Metrics
- App size < 50MB
- Launch time < 2 seconds
- Smooth animations (60 fps)
- Battery usage within platform guidelines

### 12.2 User Metrics
- Task completion rate
- Configuration save frequency
- Session duration
- Feature usage statistics

This PRD serves as a comprehensive guide for the development and maintenance of the TaskTimer app. It should be regularly reviewed and updated as the project evolves and new requirements emerge. 