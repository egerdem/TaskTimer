# RFC 002: Task Management Enhancements

## Status
- Status: Proposed
- Created: 2024-02-08
- Target Version: 1.1.0

## Overview
This RFC proposes enhancing the task management system with drag-and-drop reordering capabilities, improved task linking, and better state management for tasks.

## Motivation
Current task management implementation lacks several key features that would improve user experience and productivity, particularly around task organization and linking.

## Technical Details

### 1. Drag and Drop Implementation
#### 1.1 Enhanced Task List View
```swift
struct TaskListView: View {
    @Binding var tasks: [Task]
    @State private var draggedTask: Task?
    
    var body: some View {
        List {
            ForEach(tasks) { task in
                TaskCardView(task: binding(for: task))
                    .draggable(task.id.uuidString) {
                        TaskCardView(task: binding(for: task))
                            .frame(width: 300)
                    }
                    .dropDestination(for: String.self) { items, location in
                        handleDrop(of: items, at: location, task: task)
                    }
            }
        }
        .onChange(of: tasks) { saveTaskOrder() }
    }
    
    private func handleDrop(of items: [String], at location: CGPoint, task: Task) -> Bool {
        guard let sourceID = items.first,
              let sourceUUID = UUID(uuidString: sourceID),
              let sourceIndex = tasks.firstIndex(where: { $0.id == sourceUUID }),
              let destinationIndex = tasks.firstIndex(where: { $0.id == task.id })
        else { return false }
        
        withAnimation {
            let task = tasks.remove(at: sourceIndex)
            tasks.insert(task, at: destinationIndex)
        }
        return true
    }
}
```

### 2. Enhanced Task Linking
#### 2.1 Task Link Model
```swift
struct TaskLink: Identifiable, Codable {
    let id: UUID
    let sourceTaskId: UUID
    let targetTaskId: UUID
    var linkType: LinkType
    var conditions: LinkConditions
    
    enum LinkType: Codable {
        case sequential    // Start when previous ends
        case parallel     // Start simultaneously
        case conditional  // Start based on condition
    }
    
    struct LinkConditions: Codable {
        var startDelay: TimeInterval?
        var requiredTaskStatus: TaskStatus?
    }
}
```

#### 2.2 Link Management
```swift
class TaskLinkManager: ObservableObject {
    @Published private(set) var links: [TaskLink] = []
    
    func addLink(_ source: UUID, to target: UUID, type: TaskLink.LinkType) {
        // Verify no circular dependencies
        guard !wouldCreateCircularDependency(source: source, target: target) else {
            return
        }
        
        let link = TaskLink(
            id: UUID(),
            sourceTaskId: source,
            targetTaskId: target,
            linkType: type,
            conditions: .init()
        )
        
        links.append(link)
    }
    
    private func wouldCreateCircularDependency(source: UUID, target: UUID) -> Bool {
        var visited = Set<UUID>()
        var queue = [target]
        
        while !queue.isEmpty {
            let current = queue.removeFirst()
            if current == source { return true }
            visited.insert(current)
            
            let nextTasks = links
                .filter { $0.sourceTaskId == current }
                .map { $0.targetTaskId }
            
            queue.append(contentsOf: nextTasks.filter { !visited.contains($0) })
        }
        
        return false
    }
}
```

### 3. Task State Management
#### 3.1 Enhanced Task Model
```swift
struct Task: Identifiable, Codable {
    let id: UUID
    var title: String
    var status: TaskStatus
    var timerState: TimerState
    var displayOrder: Int
    var metadata: TaskMetadata
    
    struct TaskMetadata: Codable {
        var createdAt: Date
        var lastModified: Date
        var completionHistory: [Date]
        var tags: Set<String>
    }
    
    enum TaskStatus: Codable {
        case notStarted
        case inProgress
        case completed
        case paused
        case blocked(reason: String)
    }
}
```

#### 3.2 Task State Transitions
```swift
extension Task {
    mutating func updateStatus(_ newStatus: TaskStatus) {
        let oldStatus = self.status
        self.status = newStatus
        
        switch (oldStatus, newStatus) {
        case (_, .completed):
            metadata.completionHistory.append(Date())
        case (.completed, _):
            // Handle uncompleting a task
            break
        case (_, .inProgress):
            if case .notStarted = oldStatus {
                metadata.lastModified = Date()
            }
        default:
            break
        }
    }
}
```

## Implementation Steps
1. Implement drag and drop functionality
2. Create TaskLink model and manager
3. Enhance Task model with new properties
4. Implement state management system
5. Add circular dependency detection
6. Create UI for link management
7. Implement persistence for new features
8. Add visual indicators for task relationships

## Migration Strategy
- Existing tasks will need to be updated with new properties
- Add default values for new fields
- Preserve existing task orders during migration

## Testing Requirements
1. Drag and drop functionality:
   - Within list boundaries
   - Across different sections
   - With animations
2. Task linking:
   - Circular dependency prevention
   - Link validation
   - State propagation
3. State management:
   - All state transitions
   - Data persistence
   - Undo/redo support

## Security Considerations
- Validate all task state transitions
- Ensure proper data sanitization
- Implement proper error handling

## Timeline
- Development: 1.5 weeks
- Testing: 4 days
- Documentation: 1 day
- Total: 2 weeks

## Future Considerations
- Support for complex task dependencies
- Advanced task filtering and sorting
- Task templates
- Batch operations on tasks 