import SwiftUI

struct Task: Identifiable {
    let id = UUID()
    var title: String
    var elapsedTime: TimeInterval = 0
    var timerRunning: Bool = false
    var timerType: TimerType = .stopwatch
    var countdownTime: TimeInterval = 60 // Default 1 minute for countdown timer
    var backgroundColor: Color

    enum TimerType {
        case stopwatch
        case countdown
    }
}

struct TaskCardView: View {
    @Binding var task: Task
    @State private var timer: Timer?
    @State private var selectedMinutes: Int = 0
    @State private var selectedSeconds: Int = 0
    
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
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 1)
                        .padding(.leading, 30) // Adjust this value as needed
                }
                
                Spacer()
                ZStack {
                    if task.timerType == .stopwatch {
                        Text(formatTime(task.elapsedTime))
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                    } else {
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
                .frame(height: 90)  // Fixed height for both stopwatch and timer
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
            .background(Color(.systemGray6))
            .cornerRadius(12, corners: [.bottomLeft, .bottomRight])
        }
        .background(task.backgroundColor)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2) // Reduced shadow
        .padding(.horizontal, 10) // Reduced horizontal padding
        .padding(.vertical, 5)   // Reduced vertical padding
        .frame(height: 180)  // Slightly reduced height for the entire card
        .onAppear(perform: updateInputs)
        .onChange(of: task.timerType) { _, _ in updateInputs() }
        .onChange(of: selectedMinutes) { _, _ in updateCountdownTime() }
        .onChange(of: selectedSeconds) { _, _ in updateCountdownTime() }
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if task.timerType == .stopwatch {
                task.elapsedTime += 1
            } else {
                if task.countdownTime > 0 {
                    task.countdownTime -= 1
                } else {
                    task.timerRunning = false
                    timer?.invalidate()
                }
            }
            updateInputs()
        }
    }
    
    private func pauseTimer() {
        timer?.invalidate()
    }
    
    private func resetTimer() {
        timer?.invalidate()
        task.timerRunning = false
        if task.timerType == .stopwatch {
            task.elapsedTime = 0
        } else {
            updateCountdownTime()
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
        task.countdownTime = TimeInterval(selectedMinutes * 60 + selectedSeconds)
    }
}

struct ContentView: View {
    @State private var tasks: [Task] = [Task(title: "", backgroundColor: Color(UIColor.systemBackground))]
    @State private var showSettings = false
    @State private var useRandomColors = false
    @State private var showingSaveConfirmation: Bool = false
    @State private var showingSaveModal = false
    @State private var configName: String = ""
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationView {
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach($tasks) { $task in
                            TaskCardView(task: $task)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        withAnimation {
                                            deleteTask(task: task)
                                        }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                        
                        Button(action: addTask) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Add New Task")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                        }
                        .padding(.top, 20)
                    }
                    .padding()
                }
                .navigationTitle("TaskTimer")
                .navigationBarItems(trailing: 
                    Button(action: { showingSaveModal = true }) {
                        Image(systemName: "square.and.arrow.down")
                    }
                )
                
                if showingSaveModal {
                    Color.black.opacity(0.3)
                        .edgesIgnoringSafeArea(.all)
                        .onTapGesture {
                            showingSaveModal = false
                        }
                    
                    SaveConfigurationView(configName: $configName, onSave: saveAllConfigurations)
                        .transition(.scale)
                }
            }
            .alert(isPresented: $showingSaveConfirmation) {
                Alert(
                    title: Text("Configuration Saved"),
                    message: Text("Your timer configuration '\(configName)' has been saved successfully."),
                    dismissButton: .default(Text("OK"))
                )
            }
            .tabItem {
                Image(systemName: "list.bullet")
                Text("Tasks")
            }
            .tag(0)
            
            SettingsView(useRandomColors: $useRandomColors)
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
                .tag(1)
        }
    }
    
    private func addTask() {
        let newColor = useRandomColors ? Color.random().opacity(0.2) : Color(.systemBackground)
        tasks.append(Task(title: "", backgroundColor: newColor))
    }
    
    private func deleteTask(task: Task) {
        tasks.removeAll { $0.id == task.id }
    }
    
    private func saveAllConfigurations() {
        // Implement save logic here
        print("Saving all configurations with name: \(configName)")
        showingSaveConfirmation = true
        showingSaveModal = false
    }
}

struct SaveConfigurationView: View {
    @Binding var configName: String
    var onSave: () -> Void
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack(spacing: 20) {
            Text("Save Configuration")
                .font(.headline)
            
            TextField("Configuration Name", text: $configName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            
            HStack(spacing: 20) {
                Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
                
                Button("Save") {
                    onSave()
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

struct SettingsView: View {
    @Binding var useRandomColors: Bool

    var body: some View {
        Form {
            Toggle("Use Random Colors for Cards", isOn: $useRandomColors)
        }
        .navigationTitle("Settings")
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

#Preview {
    ContentView()
}
