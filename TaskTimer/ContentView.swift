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
                TextField("Enter task title", text: $task.title)
                    .font(.headline)
                    .foregroundColor(task.title.isEmpty ? Color(.placeholderText) : .primary)
                    .padding()
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
            .background(Color(.systemBackground))
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

    var body: some View {
        NavigationView {
            VStack {
                ScrollView {
                    VStack(spacing: 0) { // Negative spacing to overlap cards slightly
                        ForEach($tasks) { $task in
                            TaskCardView(task: $task)
                                .gesture(DragGesture().onEnded { value in
                                    if value.translation.width < -50 {
                                        deleteTask(task: task)
                                    }
                                })
                        }
                    }
                    .padding(.vertical, 5) // Reduced vertical padding
                }
                
                Button(action: addTask) {
                    Image(systemName: "plus")
                        .font(.system(size: 24))
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .clipShape(Circle())
                }
                .padding(.bottom, 20)
            }
            .navigationTitle("TaskTimer")
            .toolbar {
                Button(action: { showSettings.toggle() }) {
                    Image(systemName: "gear")
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView(useRandomColors: $useRandomColors)
            }
        }
    }
    
    private func addTask() {
        let newColor = useRandomColors ? Color.random().opacity(0.2) : Color(.systemBackground)
        tasks.append(Task(title: "", backgroundColor: newColor))
    }
    
    private func deleteTask(task: Task) {
        tasks.removeAll { $0.id == task.id }
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
