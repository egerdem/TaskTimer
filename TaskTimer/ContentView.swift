import SwiftUI

struct Task: Identifiable, Codable {
    let id: UUID
    var title: String
    var elapsedTime: TimeInterval
    var timerRunning: Bool
    var timerType: TimerType
    var countdownTime: TimeInterval
    var initialCountdownTime: TimeInterval
    var backgroundColor: Color
    var offset: CGFloat
    var buttonColor: Color
    var isDeleting: Bool = false
    var nextTaskId: UUID?  // ID of the next task to start
    var isCompleted: Bool = false

    enum TimerType: Codable {
        case stopwatch
        case countdown
    }
    
    init(id: UUID = UUID(), title: String, elapsedTime: TimeInterval = 0, timerRunning: Bool = false, timerType: TimerType = .stopwatch, countdownTime: TimeInterval = 60, initialCountdownTime: TimeInterval? = nil, backgroundColor: Color, offset: CGFloat = 0, buttonColor: Color, isDeleting: Bool = false, nextTaskId: UUID? = nil, isCompleted: Bool = false) {
        self.id = id
        self.title = title
        self.elapsedTime = elapsedTime
        self.timerRunning = timerRunning
        self.timerType = timerType
        self.countdownTime = countdownTime
        self.initialCountdownTime = initialCountdownTime ?? countdownTime
        self.backgroundColor = backgroundColor
        self.offset = offset
        self.buttonColor = buttonColor
        self.isDeleting = isDeleting
        self.nextTaskId = nextTaskId
        self.isCompleted = isCompleted
    }
    
    enum CodingKeys: String, CodingKey {
        case id, title, elapsedTime, timerRunning, timerType, countdownTime, 
             initialCountdownTime, backgroundColor, offset, buttonColor, isDeleting, 
             nextTaskId, isCompleted
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        elapsedTime = try container.decode(TimeInterval.self, forKey: .elapsedTime)
        timerRunning = try container.decode(Bool.self, forKey: .timerRunning)
        timerType = try container.decode(TimerType.self, forKey: .timerType)
        countdownTime = try container.decode(TimeInterval.self, forKey: .countdownTime)
        initialCountdownTime = try container.decode(TimeInterval.self, forKey: .initialCountdownTime)
        let colorComponents = try container.decode([CGFloat].self, forKey: .backgroundColor)
        backgroundColor = Color(.sRGB, red: colorComponents[0], green: colorComponents[1], blue: colorComponents[2], opacity: colorComponents[3])
        offset = try container.decode(CGFloat.self, forKey: .offset)
        let buttonColorComponents = try container.decode([CGFloat].self, forKey: .buttonColor)
        buttonColor = Color(.sRGB, red: buttonColorComponents[0], green: buttonColorComponents[1], blue: buttonColorComponents[2], opacity: buttonColorComponents[3])
        isDeleting = try container.decode(Bool.self, forKey: .isDeleting)
        nextTaskId = try container.decode(UUID?.self, forKey: .nextTaskId)
        isCompleted = try container.decode(Bool.self, forKey: .isCompleted)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(elapsedTime, forKey: .elapsedTime)
        try container.encode(timerRunning, forKey: .timerRunning)
        try container.encode(timerType, forKey: .timerType)
        try container.encode(countdownTime, forKey: .countdownTime)
        try container.encode(initialCountdownTime, forKey: .initialCountdownTime)
        let uiColor = UIColor(backgroundColor)
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        try container.encode([red, green, blue, alpha], forKey: .backgroundColor)
        try container.encode(offset, forKey: .offset)
        let buttonUiColor = UIColor(buttonColor)
        var buttonRed: CGFloat = 0, buttonGreen: CGFloat = 0, buttonBlue: CGFloat = 0, buttonAlpha: CGFloat = 0
        buttonUiColor.getRed(&buttonRed, green: &buttonGreen, blue: &buttonBlue, alpha: &buttonAlpha)
        try container.encode([buttonRed, buttonGreen, buttonBlue, buttonAlpha], forKey: .buttonColor)
        try container.encode(isDeleting, forKey: .isDeleting)
        try container.encode(nextTaskId, forKey: .nextTaskId)
        try container.encode(isCompleted, forKey: .isCompleted)
    }
}

struct TaskCardView: View {
    @Binding var task: Task
    @Binding var allTasks: [Task]  // Add access to all tasks
    @State private var timer: Timer?
    @State private var selectedMinutes: Int = 0
    @State private var selectedSeconds: Int = 0
    @State private var isBeingDeleted = false
    
    private func startNextTask() {
        guard let nextTaskId = task.nextTaskId else { return }
        
        // Verify the task still exists in allTasks
        guard let nextTaskIndex = allTasks.firstIndex(where: { $0.id == nextTaskId }),
              nextTaskIndex < allTasks.count else {
            // If the next task doesn't exist anymore, clear the link
            task.nextTaskId = nil
            return
        }
        
        withAnimation {
            if allTasks[nextTaskIndex].timerType == .countdown {
                allTasks[nextTaskIndex].countdownTime = allTasks[nextTaskIndex].initialCountdownTime
            }
            allTasks[nextTaskIndex].timerRunning = true
            allTasks[nextTaskIndex].isCompleted = false
        }
    }
    
    private func checkCompletion() {
        if task.timerType == .countdown && task.countdownTime <= 0 {
            task.isCompleted = true
            task.timerRunning = false
            timer?.invalidate()
            
            // Reset this timer's countdown to initial value
            task.countdownTime = task.initialCountdownTime
            
            // Start the next task
            startNextTask()
        }
    }
    
    private func startTimer() {
        timer?.invalidate()
        
        // Don't start timer if task is being deleted
        guard !isBeingDeleted else { return }
        
        // If starting a fresh countdown, reset to initial time
        if task.timerType == .countdown && !task.timerRunning {
            task.countdownTime = task.initialCountdownTime
        }
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [self] timer in
            guard !isBeingDeleted,  // Check if being deleted
                  task.timerRunning else {
                timer.invalidate()
                return
            }
            
            if task.timerType == .stopwatch {
                task.elapsedTime += 1
            } else {
                if task.countdownTime > 0 {
                    task.countdownTime -= 1
                    checkCompletion()
                } else {
                    task.timerRunning = false
                    timer.invalidate()
                }
            }
            updateInputs()
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Image(systemName: "pencil")
                            .foregroundColor(.gray)
                        TextField("Enter task title", text: $task.title)
                            .font(.headline)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                    
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 1)
                        .padding(.leading, 40) // Shifted to the right
                }
                
                Spacer()
                ZStack {
                    if task.timerType == .stopwatch {
                        Text(formatTime(task.elapsedTime))
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                    } else {
                        if task.timerRunning {
                            // Show countdown display when running
                            Text(formatTime(task.countdownTime))
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                                .onTapGesture {
                                    // Allow stopping timer to edit time
                                    task.timerRunning = false
                                }
                        } else {
                            // Show time picker when not running
                            HStack(spacing: 0) {
                                Picker("Minutes", selection: $selectedMinutes) {
                                    ForEach(0..<60) { minute in
                                        Text("\(minute)")
                                            .tag(minute)
                                            .font(.system(size: 28, weight: .bold, design: .rounded))
                                    }
                                }
                                .pickerStyle(WheelPickerStyle())
                                .frame(width: 60)
                                .clipped()
                                
                                Text(":")
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                
                                Picker("Seconds", selection: $selectedSeconds) {
                                    ForEach(0..<60) { second in
                                        Text("\(second)")
                                            .tag(second)
                                            .font(.system(size: 28, weight: .bold, design: .rounded))
                                    }
                                }
                                .pickerStyle(WheelPickerStyle())
                                .frame(width: 60)
                                .clipped()
                            }
                        }
                    }
                }
                .frame(height: 90)
                .padding(.horizontal)
            }
            .cornerRadius(12, corners: [.topLeft, .topRight])
            
            HStack(spacing: 8) {
                Button(action: {
                    task.timerRunning.toggle()
                    if task.timerRunning {
                        startTimer()
                    } else {
                        pauseTimer()
                    }
                }) {
                    Text(task.timerRunning ? "Pause" : "Start")
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(task.timerRunning ? Color.orange : Color.green)
                        .cornerRadius(8)
                }
                
                Button(action: resetTimer) {
                    Text("Reset")
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.red)
                        .cornerRadius(8)
                }
                
                Picker("", selection: $task.timerType) {
                    Image(systemName: "stopwatch").tag(Task.TimerType.stopwatch)
                    Image(systemName: "timer").tag(Task.TimerType.countdown)
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(maxWidth: .infinity)
            }
            .padding(10)
            .background(.white)
            .cornerRadius(12, corners: [.bottomLeft, .bottomRight])
            
            if task.timerType == .countdown {
                HStack {
                    Menu {
                        ForEach(allTasks.filter { $0.id != task.id }) { nextTask in
                            Button(action: {
                                withAnimation {
                                    task.nextTaskId = nextTask.id
                                }
                            }) {
                                HStack {
                                    Text(nextTask.title.isEmpty ? "Untitled" : nextTask.title)
                                    if task.nextTaskId == nextTask.id {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                        
                        if task.nextTaskId != nil {
                            Button("Remove Link") {
                                withAnimation {
                                    task.nextTaskId = nil
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: "link")
                            Text("Connect a Task")
                        }
                        .font(.caption)
                        .foregroundColor(.gray)
                    }
                    
                    // Connection indicator next to the button
                    if let nextTaskId = task.nextTaskId,
                       let nextTask = allTasks.first(where: { $0.id == nextTaskId }) {
                        Text("\(task.title.isEmpty ? "Untitled" : task.title) → \(nextTask.title.isEmpty ? "Untitled" : nextTask.title)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    if let previousTask = allTasks.first(where: { $0.nextTaskId == task.id }) {
                        Text("\(task.title.isEmpty ? "Untitled" : task.title) ← \(previousTask.title.isEmpty ? "Untitled" : previousTask.title)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.vertical, 4)
                .padding(.bottom, 8)
            }
        }
        .background(task.backgroundColor) // text field color
        .cornerRadius(12)
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
        .frame(height: 180)
        .onAppear(perform: updateInputs)
        .onChange(of: task.timerType) { _, _ in updateInputs() }
        .onChange(of: selectedMinutes) { _, _ in updateCountdownTime() }
        .onChange(of: selectedSeconds) { _, _ in updateCountdownTime() }
        .onChange(of: task.timerRunning) { oldValue, newValue in
            if newValue {
                startTimer()
            }
        }
        .onChange(of: task.isDeleting) { _, newValue in
            if newValue {
                isBeingDeleted = true
                timer?.invalidate()
                task.timerRunning = false
            }
        }
    }
    
    private func pauseTimer() {
        timer?.invalidate()
    }
    
    private func resetTimer() {
        timer?.invalidate()
        task.timerRunning = false
        task.isCompleted = false
        if task.timerType == .stopwatch {
            task.elapsedTime = 0
        } else {
            task.countdownTime = task.initialCountdownTime
            selectedMinutes = Int(task.initialCountdownTime) / 60
            selectedSeconds = Int(task.initialCountdownTime) % 60
        }
        updateInputs()
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func updateInputs() {
        if task.timerType == .countdown {
            selectedMinutes = Int(task.countdownTime) / 60
            selectedSeconds = Int(task.countdownTime) % 60
        } else {
            selectedMinutes = Int(task.elapsedTime) / 60
            selectedSeconds = Int(task.elapsedTime) % 60
        }
    }
    
    private func updateCountdownTime() {
        let newTime = TimeInterval(selectedMinutes * 60 + selectedSeconds)
        task.countdownTime = newTime
        
        // Only update initialCountdownTime if it hasn't been set yet or if we're explicitly resetting
        if task.initialCountdownTime == 0 || !task.timerRunning {
            task.initialCountdownTime = newTime
        }
    }
}

struct ContentView: View {
    @StateObject private var configManager = ConfigurationManager()
    @State private var tasks: [Task] = [Task(title: "", backgroundColor: Color.white, buttonColor: Color.blue)]
    @State private var useRandomColors = false
    @State private var showingSaveConfirmation: Bool = false
    @State private var showingSaveModal = false
    @State private var configName: String = ""
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                mainTaskView
                    .navigationTitle("TaskTimer")
            }
            .tabItem {
                Image(systemName: "list.bullet")
                Text("Tasks")
            }
            .tag(0)
            
            NavigationStack {
                SavedConfigsView(configManager: configManager, onLoadConfig: loadConfiguration)
                    .navigationTitle("Saved Tasks")
            }
            .tabItem {
                Image(systemName: "folder")
                Text("Saved Tasks")
            }
            .tag(1)
            
            NavigationStack {
                SettingsView(useRandomColors: $useRandomColors)
                    .navigationTitle("Settings")
            }
            .tabItem {
                Image(systemName: "gear")
                Text("Settings")
            }
            .tag(2)
        }
        .onAppear(perform: configManager.loadConfigurations)
    }
    
    // Extract main task view into a computed property
    private var mainTaskView: some View {
        ZStack {
            taskListView
            
            if showingSaveModal {
                Color.black.opacity(0.5)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        showingSaveModal = false
                    }
                
                SaveConfigurationView(configName: $configName, 
                                   isPresented: $showingSaveModal, 
                                   onSave: saveAllConfigurations)
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingSaveModal = true
                }) {
                    Image(systemName: "square.and.arrow.down")
                }
            }
        }
    }
    
    private var taskListView: some View {
        GeometryReader { geometry in
            if tasks.isEmpty {
                // When there are no tasks, show the add button near the top
                VStack {
                    Button(action: addTask) {
                        Image(systemName: "plus")
                            .font(.title)
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(Color.blue)
                            .clipShape(Circle())
                            .shadow(radius: 5)
                    }
                    .padding(.top, geometry.size.height * 0.2) // Position at 20% from the top
                    
                    Spacer() // Push the button up
                }
                .frame(maxWidth: .infinity)
                .background(Color(.systemGray6))
            } else {
                // When there are tasks, show the scrollable list
                ScrollView {
                    VStack(spacing: 2) {
                        ForEach(tasks) { task in
                            TaskCardView(task: binding(for: task), allTasks: $tasks)
                                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                                .overlay(
                                    GeometryReader { geometry in
                                        HStack {
                                            Spacer()
                                            Button(action: {
                                                withAnimation {
                                                    if let index = tasks.firstIndex(where: { $0.id == task.id }) {
                                                        tasks[index].timerRunning = false
                                                        deleteTask(task.id)
                                                    }
                                                }
                                            }) {
                                                Image(systemName: "trash")
                                                    .foregroundColor(.white)
                                                    .frame(width: min(-task.offset * 0.5, 80), height: geometry.size.height)
                                                    .background(Color.red)
                                            }
                                            .opacity(task.offset < 0 ? 1 : 0)
                                        }
                                    }
                                )
                                .offset(x: task.offset)
                                .gesture(
                                    DragGesture()
                                        .onChanged { gesture in
                                            if gesture.translation.width < 0 {
                                                if let index = tasks.firstIndex(where: { $0.id == task.id }),
                                                   !tasks[index].isDeleting {
                                                    tasks[index].offset = gesture.translation.width
                                                }
                                            }
                                        }
                                        .onEnded { _ in
                                            withAnimation {
                                                guard let index = tasks.firstIndex(where: { $0.id == task.id }),
                                                      !tasks[index].isDeleting else { return }
                                                
                                                if tasks[index].offset < -80 {
                                                    deleteTask(task.id)
                                                }
                                                tasks[index].offset = 0
                                            }
                                        }
                                )
                                .transition(.opacity)
                        }
                        
                        Button(action: addTask) {
                            Image(systemName: "plus")
                                .font(.title)
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                                .background(Color.blue)
                                .clipShape(Circle())
                                .shadow(radius: 5)
                        }
                        .padding(.vertical, 10)
                    }
                    .padding(8)
                }
            }
        }
        .background(Color(.systemGray6).edgesIgnoringSafeArea(.all))
    }
    
    private func binding(for task: Task) -> Binding<Task> {
        Binding(
            get: {
                // Return the task if it exists, otherwise return a default task
                self.tasks.first(where: { $0.id == task.id }) ?? 
                    Task(title: "", backgroundColor: Color.white, buttonColor: Color.blue)
            },
            set: { newValue in
                // Only update if the task still exists
                if let index = self.tasks.firstIndex(where: { $0.id == task.id }) {
                    self.tasks[index] = newValue
                }
            }
        )
    }
    
    private func addTask() {
        withAnimation {
            let newColor = useRandomColors ? Color.random().opacity(0.2) : Color(.systemBackground)
            let buttonColor = useRandomColors ? Color.random() : Color.blue
            tasks.append(Task(title: "", backgroundColor: newColor, buttonColor: buttonColor))
        }
    }
    
    private func deleteTask(_ id: UUID) {
        // Create a local copy of the task before deletion
        guard let taskToDelete = tasks.first(where: { $0.id == id }) else { return }
        
        // Mark for deletion first
        if let index = tasks.firstIndex(where: { $0.id == taskToDelete.id }) {
            withAnimation {
                // Mark the task for deletion and stop timer
                var updatedTask = taskToDelete
                updatedTask.isDeleting = true
                updatedTask.timerRunning = false
                tasks[index] = updatedTask
                
                // Clear any links to this task immediately
                tasks = tasks.map { task in
                    var updatedTask = task
                    if updatedTask.nextTaskId == id {
                        updatedTask.nextTaskId = nil
                    }
                    return updatedTask
                }
            }
            
            // Remove the task after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation {
                    self.tasks.removeAll { $0.id == taskToDelete.id }
                }
            }
        }
    }
    
    private func saveAllConfigurations() {
        let newConfig = SavedConfig(name: configName, tasks: tasks)
        configManager.savedConfigs.append(newConfig)
        configManager.saveConfigurations()
        showingSaveConfirmation = true
        showingSaveModal = false
    }
    
    private func loadConfiguration(_ config: SavedConfig) {
        tasks = config.tasks
        selectedTab = 0 // Switch to the Tasks tab
    }
}

struct SaveConfigurationView: View {
    @Binding var configName: String
    @Binding var isPresented: Bool
    var onSave: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("Save Task")
                .font(.headline)
            
            TextField("Give a name", text: $configName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            
            HStack(spacing: 20) {
                Button("Cancel") {
                    isPresented = false
                }
                
                Button("Save") {
                    onSave()
                    isPresented = false
                }
                .disabled(configName.isEmpty)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(radius: 10)
        .frame(width: 300, height: 200)
    }
}

struct BackgroundClearView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        DispatchQueue.main.async {
            view.superview?.superview?.backgroundColor = .clear
        }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}

struct SettingsView: View {
    @Binding var useRandomColors: Bool

    var body: some View {
        Form {
            Toggle("Use Random Colors for Cards", isOn: $useRandomColors)
        }
    }
}

struct SavedConfigsView: View {
    @ObservedObject var configManager: ConfigurationManager
    var onLoadConfig: (SavedConfig) -> Void

    var body: some View {
        List {
            ForEach(configManager.savedConfigs) { config in
                VStack(alignment: .leading) {
                    Text(config.name)
                        .font(.headline)
                    Text("\(config.tasks.count) tasks")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    onLoadConfig(config)
                }
            }
            .onDelete(perform: deleteConfig)
        }
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGray6).edgesIgnoringSafeArea(.all))
    }

    private func deleteConfig(at offsets: IndexSet) {
        configManager.savedConfigs.remove(atOffsets: offsets)
        configManager.saveConfigurations()
    }
}

struct SavedConfig: Identifiable, Codable {
    let id: UUID
    let name: String
    let tasks: [Task]
    
    init(id: UUID = UUID(), name: String, tasks: [Task]) {
        self.id = id
        self.name = name
        self.tasks = tasks
    }
}

extension Color {
    static func random() -> Color {
        Color(red: .random(in: 0...1), green: .random(in: 0...1), blue: .random(in: 0...1))
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

class ConfigurationManager: ObservableObject {
    @Published var savedConfigs: [SavedConfig] = []
    
    func saveConfigurations() {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(savedConfigs) {
            UserDefaults.standard.set(encoded, forKey: "SavedConfigurations")
        }
    }
    
    func loadConfigurations() {
        if let savedConfigs = UserDefaults.standard.data(forKey: "SavedConfigurations") {
            let decoder = JSONDecoder()
            if let loadedConfigs = try? decoder.decode([SavedConfig].self, from: savedConfigs) {
                self.savedConfigs = loadedConfigs
            }
        }
    }
}

#Preview {
    ContentView()
}
