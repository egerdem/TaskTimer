
Project Overview: TaskTimer
TaskTimer is a SwiftUI-based iOS productivity application designed to allow users to manage multiple timers and stopwatches simultaneously, with the ability to save (and later load) custom configurations. A “configuration” in this context includes the number and order of timers/stopwatches, any user-defined names, and parameters (like countdown times or stopwatch settings).

Key Goals
Multiple Timers & Stopwatches: Users can create more than one timer or stopwatch at once.
Easy Configuration Management: Users can save their current arrangement (with all timer/stopwatch details) and retrieve it later.
Modern SwiftUI Patterns: The UI is built entirely in SwiftUI, leveraging tab navigation, gestures, and iOS design best practices.
Data Persistence: Timer configurations and user settings are saved and restored using UserDefaults (or another recommended approach in Swift).
Project Structure
Xcode Project
Follows a standard iOS app structure.
Contains typical configuration files (like .gitignore, project.pbxproj).
Swift Package Manager (optional)
If relevant, you can describe Swift packages or frameworks used (if any).
Preview Content
Included for SwiftUI previews.
Main Code Components
1. TaskTimerApp.swift
Description: Entry point of the application.
Role: Initializes the app and sets up the root view (ContentView) for display.
2. ContentView.swift
Description: Main SwiftUI view containing the majority of the application logic.
Tabs / Navigation: Could include tabs for “Tasks”, “Saved Configs”, and “Settings”.
Functionality:
Creates new timers/stopwatches.
Switches between stopwatch and countdown modes.
Persists user preferences and selected configurations.
3. Task Model (Struct)
Properties:
title: User-defined name (e.g., “Pasta Boil”).
timerType: Either .stopwatch or .countdown.
elapsedTime: Holds the current time counted.
backgroundColor: A color used to visually differentiate tasks.
timerState: Tracks if the timer/stopwatch is active, paused, or stopped.
4. TaskCardView.swift
Description: A reusable SwiftUI view representing an individual task (timer/stopwatch).
Controls: Start, pause, reset, and color randomization.
5. SavedConfigsView.swift
Description: Displays a list of previously saved timer configurations.
Actions: Load or delete saved configurations.
6. SettingsView.swift
Description: Allows the user to manage global app settings.
7. SaveConfigurationView.swift
Description: A modal (or sheet) view for saving the user’s current tasks (timers & stopwatches) as a named configuration.
Feature Highlights
Create Multiple Timers/Stopwatches

Add new tasks in either stopwatch or countdown mode.
Customize each task’s name (e.g., “Pasta Boil”, “Wait Before Serve”).
Save & Load Configurations

Save the current set of tasks (including their order, mode, and names).
Load these configurations later to quickly restore the setup.
Swipe-to-Delete

Remove individual tasks or configurations with swipe gestures.
Random Color Generation

Option to assign a random background color to each task card.
Persistence

Data stored in UserDefaults for quick retrieval.
Potential future upgrades: Migrate to Core Data or CloudKit for more robust data management.
Technical Considerations
SwiftUI Lifecycle: Uses the SwiftUI App protocol (TaskTimerApp), meaning no AppDelegate/SceneDelegate overhead.
Environment Objects: Consider using @StateObject or @EnvironmentObject for central data storage if multiple views need to update timers in real-time.
Timer Management:
SwiftUI’s Timer publisher or DispatchTimer could be used to update each task’s elapsed time.
Must handle background/foreground transitions properly (e.g., store a timestamp upon backgrounding, then calculate the difference on re-entry).
User Defaults:
The current design references UserDefaults for saving/loading configurations.
For more scalable solutions, consider adopting Codable models in conjunction with property wrappers or Core Data.
Roadmap / Future Enhancements
Notifications: Notify the user when a countdown timer finishes.
Widget Support: Enable quick interactions (start/pause/reset) from the home screen.