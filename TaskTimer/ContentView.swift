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
    @State private var minutesInput: String = "00"
    @State private var secondsInput: String = "00"
    
    var body: some View {
        HStack {
            TextField("Enter task title", text: $task.title)
                .background(Color.clear)
                .textFieldStyle(PlainTextFieldStyle())
                .padding(.horizontal)
                .foregroundColor(task.title.isEmpty ? Color.gray : Color.primary)

            Divider()

            VStack {
                if task.timerType == .stopwatch {
                    Text(formatTime(task.elapsedTime))
                        .font(.system(size: 24, weight: .bold))
                        .frame(width: 100)
                } else {
                    HStack {
                        TextField("Min", text: $minutesInput)
                            .keyboardType(.numberPad)
                            .font(.system(size: 24, weight: .bold))
                            .multilineTextAlignment(.center)
                            .frame(width: 40)
                        
                        Text(":")
                            .font(.system(size: 24, weight: .bold))
                        
                        TextField("Sec", text: $secondsInput)
                            .keyboardType(.numberPad)
                            .font(.system(size: 24, weight: .bold))
                            .multilineTextAlignment(.center)
                            .frame(width: 40)
                    }
                }

                HStack {
                    Button(action: {
                        task.timerRunning.toggle()
                        if task.timerRunning {
                            startTimer()
                        } else {
                            pauseTimer()
                        }
                    }) {
                        Text(task.timerRunning ? "Pause" : "Start")
                            .font(.system(size: 12))
                            .foregroundColor(.black)
                            .frame(width: 60, height: 40)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(task.timerRunning ? Color.red.opacity(0.7) : Color.green.opacity(0.7))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.black, lineWidth: 1)
                            )
                    }

                    Button(action: resetTimer) {
                        Text("Reset")
                            .font(.system(size: 12))
                            .foregroundColor(.black)
                            .frame(width: 60, height: 40)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.gray.opacity(0.3))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.black, lineWidth: 1)
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
        .background(task.backgroundColor)
        .cornerRadius(10)
        .shadow(radius: 5)
        .padding()
        .onAppear(perform: updateInputs)
        .onChange(of: task.timerType) { _ in updateInputs() }
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            if task.timerType == .stopwatch {
                task.elapsedTime += 0.1
            } else {
                if task.countdownTime > 0 {
                    task.countdownTime -= 0.1
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
            task.countdownTime = TimeInterval(Int(minutesInput) ?? 0) * 60 + TimeInterval(Int(secondsInput) ?? 0)
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
            let minutes = Int(task.countdownTime) / 60
            let seconds = Int(task.countdownTime) % 60
            minutesInput = String(format: "%02d", minutes)
            secondsInput = String(format: "%02d", seconds)
        } else {
            let minutes = Int(task.elapsedTime) / 60
            let seconds = Int(task.elapsedTime) % 60
            minutesInput = String(format: "%02d", minutes)
            secondsInput = String(format: "%02d", seconds)
        }
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
                    ForEach($tasks) { $task in
                        TaskCardView(task: $task)
                            .gesture(DragGesture().onEnded { value in
                                if value.translation.width < -50 {
                                    deleteTask(task: task)
                                }
                            })
                    }
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
        let newColor = useRandomColors ? Color.random().opacity(0.2) : Color(UIColor.systemBackground)
        tasks.append(Task(title: "New Task", backgroundColor: newColor))
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
