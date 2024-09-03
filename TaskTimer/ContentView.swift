import SwiftUI

// Task struct with timerType property
struct Task: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String
    var elapsedTime: TimeInterval = 0
    var timerRunning: Bool = false
    var timerType: TimerType = .stopwatch
    var countdownTime: TimeInterval = 60 // Default 1 minute for countdown timer
    var startTime: Date? = nil
    var endTime: Date? = nil // Track when the timer should end
    var backgroundColor: Color
    var pausedElapsedTime: TimeInterval = 0

    enum TimerType: Codable, Equatable {
        case stopwatch
        case countdown
    }

    enum CodingKeys: String, CodingKey {
        case id, title, elapsedTime, timerRunning, timerType, countdownTime, startTime, endTime, backgroundColor, pausedElapsedTime
    }

    init(title: String, backgroundColor: Color) {
        self.title = title
        self.backgroundColor = backgroundColor
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        elapsedTime = try container.decode(TimeInterval.self, forKey: .elapsedTime)
        timerRunning = try container.decode(Bool.self, forKey: .timerRunning)
        timerType = try container.decode(TimerType.self, forKey: .timerType)
        countdownTime = try container.decode(TimeInterval.self, forKey: .countdownTime)
        startTime = try container.decodeIfPresent(Date.self, forKey: .startTime)
        endTime = try container.decodeIfPresent(Date.self, forKey: .endTime)
        let colorData = try container.decode(Data.self, forKey: .backgroundColor)
        backgroundColor = Color(NSKeyedUnarchiver.unarchiveObject(with: colorData) as? UIColor ?? .white)
        pausedElapsedTime = try container.decode(TimeInterval.self, forKey: .pausedElapsedTime)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(elapsedTime, forKey: .elapsedTime)
        try container.encode(timerRunning, forKey: .timerRunning)
        try container.encode(timerType, forKey: .timerType)
        try container.encode(countdownTime, forKey: .countdownTime)
        try container.encodeIfPresent(startTime, forKey: .startTime)
        try container.encodeIfPresent(endTime, forKey: .endTime)
        let uiColor = UIColor(backgroundColor)
        let colorData = try NSKeyedArchiver.archivedData(withRootObject: uiColor, requiringSecureCoding: false)
        try container.encode(colorData, forKey: .backgroundColor)
        try container.encode(pausedElapsedTime, forKey: .pausedElapsedTime)
    }

    static func == (lhs: Task, rhs: Task) -> Bool {
        return lhs.id == rhs.id &&
               lhs.title == rhs.title &&
               lhs.elapsedTime == rhs.elapsedTime &&
               lhs.timerRunning == rhs.timerRunning &&
               lhs.timerType == rhs.timerType &&
               lhs.countdownTime == rhs.countdownTime &&
               lhs.startTime == rhs.startTime &&
               lhs.endTime == rhs.endTime &&
               lhs.backgroundColor == rhs.backgroundColor &&
               lhs.pausedElapsedTime == rhs.pausedElapsedTime
    }
}

// Add this extension for random color generation
extension Color {
    static func random() -> Color {
        return Color(
            red: .random(in: 0...1),
            green: .random(in: 0...1),
            blue: .random(in: 0...1)
        )
    }
}

// TaskCardView to handle both stopwatch and timer

import SwiftUI

struct TaskCardView: View {
    @Binding var task: Task
    @State private var timer: Timer? = nil
    @State private var minutesInput: String = "00" // Default minutes input
    @State private var secondsInput: String = "00" // Default seconds input
    @State private var pausedElapsedTime: TimeInterval = 0
    var backgroundColor: Color
    
    var body: some View {
        HStack {
            // Task title text field
            TextField("Enter task title", text: $task.title)
                .background(Color.clear) // Transparent background
                .textFieldStyle(PlainTextFieldStyle())
                .padding(.horizontal)
                .foregroundColor(task.title.isEmpty ? Color.gray : Color.primary) // Change text color to gray if placeholder is shown

            Divider()

            VStack {
                // Timer text or input fields based on the selected timer type
                if task.timerType == .stopwatch {
                    Text(formatTime(task.elapsedTime))
                        .font(.system(size: 24, weight: .bold))
                        .frame(width: 100)
                } else {
                    HStack {
                        // Minutes Input
                        TextField("Min", text: $minutesInput)
                            .keyboardType(.numberPad)
                            .font(.system(size: 24, weight: .bold))
                            .multilineTextAlignment(.center)
                            .frame(width: 40)
                        
                        
                        Text(":")
                            .font(.system(size: 24, weight: .bold))
                        
                        // Seconds Input
                        TextField("Sec", text: $secondsInput)
                            .keyboardType(.numberPad)
                            .font(.system(size: 24, weight: .bold))
                            .multilineTextAlignment(.center)
                            .frame(width: 40)
                            .toolbar {
                                ToolbarItemGroup(placement: .keyboard) {
                                    Spacer()
                                    Button("Done") {
                                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                    }
                                }
                            }
                    }
                }

                HStack {
                    // Start/Pause Button
                    Button(action: {
                        if self.task.timerRunning {
                            self.pauseTimer()
                        } else {
                            self.startTimer()
                        }
                        self.task.timerRunning.toggle()
                    }) {
                        Text(task.timerRunning ? "Pause" : "Start")
                            .font(.system(size: 12))
                            .foregroundColor(.black)
                            .frame(width: 60, height: 40)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(task.timerRunning ? Color.red.opacity(0.7) : Color.green.opacity(0.7)) // Background color with rounded corners
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.black, lineWidth: 1) // Border
                            )
                    }

                    // Reset Button
                    Button(action: {
                        if self.task.timerType == .stopwatch {
                                self.resetStopwatch()
                            } else if self.task.timerType == .countdown {
                                self.resetTimer()
                            }
                    }) {
                        Text("Reset")
                            .font(.system(size: 12))
                            .foregroundColor(.black)
                            .frame(width: 60, height: 40)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill((Color.gray.opacity(0.3))) // Background color with rounded corners
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.black, lineWidth: 1) // Border
                            )
                    }
                }

                Picker("", selection: $task.timerType) {
                    Image(systemName: "stopwatch").tag(Task.TimerType.stopwatch)
                    Image(systemName: "timer").tag(Task.TimerType.countdown)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(10)
                .background(Color.white.opacity(0.8))

            }
            .padding()
        }
        .background(backgroundColor) // Apply the background color here
        .cornerRadius(10)
        .shadow(radius: 5)
        .padding()
        .onAppear {
            updateInputs()
        }
        .onChange(of: task.timerType) { _ in
            updateInputs()
        }
        .onChange(of: task.countdownTime) { _ in
            updateInputs()
        }
    }

    private func startTimer() {
        if task.timerType == .stopwatch {
            if task.startTime == nil {
                task.startTime = Date().addingTimeInterval(-pausedElapsedTime)
            }
            self.timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
                self.updateElapsedTime()
            }
        } else {
            if task.startTime == nil {
                task.startTime = Date()
                task.endTime = task.startTime?.addingTimeInterval(task.countdownTime)
            }
            self.timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
                self.updateCountdownTime()
            }
        }
    }

    private func pauseTimer() {
        self.timer?.invalidate()
        self.timer = nil
        if task.timerType == .stopwatch {
            pausedElapsedTime = task.elapsedTime
        } else {
            task.countdownTime = (task.endTime ?? Date()).timeIntervalSince(Date())
        }
        task.startTime = nil
        task.endTime = nil
    }

    private func updateElapsedTime() {
        guard let startTime = task.startTime else { return }
        let currentTime = Date()
        task.elapsedTime = currentTime.timeIntervalSince(startTime)
    }

    private func updateCountdownTime() {
        guard let endTime = task.endTime else { return }
        let currentTime = Date()
        let timeLeft = endTime.timeIntervalSince(currentTime)

        if timeLeft > 0 {
            task.countdownTime = timeLeft
            let minutes = Int(timeLeft) / 60
            let seconds = Int(timeLeft) % 60
            minutesInput = String(format: "%02d", minutes)
            secondsInput = String(format: "%02d", seconds)
        } else {
            task.countdownTime = 0
            minutesInput = "00"
            secondsInput = "00"
            timer?.invalidate()
            task.timerRunning = false
        }
    }

    private func resetStopwatch() {
        timer?.invalidate()
        timer = nil
        task.elapsedTime = 0
        pausedElapsedTime = 0
        task.startTime = nil
        task.timerRunning = false
    }
    
    private func resetTimer() {
        timer?.invalidate()
        timer = nil
        task.timerRunning = false
        task.startTime = nil
        task.endTime = nil
        minutesInput = "00"
        secondsInput = "00"
        task.countdownTime = 0
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private func updateInputs() {
        if task.timerType == .countdown {
            let minutes = Int(task.countdownTime) / 60
            let seconds = Int(task.countdownTime) % 60
            minutesInput = String(format: "%02d", minutes)
            secondsInput = String(format: "%02d", seconds)
        } else {
            minutesInput = "00"
            secondsInput = "00"
        }
    }
}

struct ContentView: View {
    @State private var tasks: [Task] = [Task(title: "", backgroundColor: Color(UIColor.systemBackground))]
    @State private var showSettings = false
    @State private var useRandomColors = false
    @State private var selectedTab = 0
    @State private var showSavePrompt = false
    @State private var configurationName = ""
    @State private var savedConfigurations: [String: [Task]] = [:]

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationView {
                VStack {
                    ScrollView {
                        VStack {
                            ForEach($tasks) { $task in
                                TaskCardView(task: $task, backgroundColor: task.backgroundColor)
                                    .frame(height: 200)
                                    .gesture(
                                        DragGesture()
                                            .onEnded { value in
                                                if value.translation.width < -50 {
                                                    withAnimation {
                                                        deleteTask(task: task)
                                                    }
                                                }
                                            }
                                    )
                            }
                        }
                    }

                    Button(action: {
                        let newBackgroundColor = useRandomColors ? Color.random().opacity(0.2) : Color(UIColor.systemBackground)
                        self.tasks.append(Task(title: "New Task", backgroundColor: newBackgroundColor))
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 24))
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .clipShape(Circle())
                            .shadow(radius: 5)
                    }
                    .padding(.bottom, 20)
                }
                .navigationTitle("TaskTimer")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            showSettings.toggle()
                        }) {
                            Image(systemName: "gear")
                        }
                    }
                }
                .sheet(isPresented: $showSettings) {
                    SettingsView(useRandomColors: $useRandomColors)
                }
                .onAppear {
                    loadConfigurations()
                }
            }
            .tabItem {
                Image(systemName: "house")
                Text("Home")
            }
            .tag(0)

            NavigationView {
                List {
                    ForEach(Array(savedConfigurations.keys), id: \.self) { key in
                        Button(action: {
                            loadConfiguration(named: key)
                        }) {
                            Text(key)
                        }
                    }
                    .onDelete(perform: deleteConfiguration)
                }
                .navigationTitle("Saved Configurations")
                .toolbar {
                    EditButton()
                }
            }
            .tabItem {
                Image(systemName: "list.bullet")
                Text("Saved")
            }
            .tag(1)
        }
    }

    private func saveConfiguration() {
        savedConfigurations[configurationName] = tasks
        saveConfigurations()
        configurationName = ""
    }

    private func loadConfiguration(named name: String) {
        if let loadedTasks = savedConfigurations[name] {
            tasks = loadedTasks.map { Task(title: $0.title, backgroundColor: $0.backgroundColor) }
            selectedTab = 0 // Switch back to the main view
        }
    }

    private func deleteConfiguration(at offsets: IndexSet) {
        let keys = Array(savedConfigurations.keys)
        for index in offsets {
            savedConfigurations.removeValue(forKey: keys[index])
        }
        saveConfigurations()
    }

    private func saveConfigurations() {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(savedConfigurations) {
            UserDefaults.standard.set(encoded, forKey: "SavedConfigurations")
        }
    }

    private func loadConfigurations() {
        if let saved = UserDefaults.standard.data(forKey: "SavedConfigurations") {
            let decoder = JSONDecoder()
            if let loaded = try? decoder.decode([String: [Task]].self, from: saved) {
                self.savedConfigurations = loaded
            }
        }
    }

    private func deleteTask(task: Task) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks.remove(at: index)
        }
    }
}

struct SettingsView: View {
    @Binding var useRandomColors: Bool
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            Form {
                Toggle("Use Random Colors for Cards", isOn: $useRandomColors)
            }
            .navigationTitle("Settings")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

//#Preview {
//    ContentView()
//}
