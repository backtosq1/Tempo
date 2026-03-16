//  Tempo - Sidebar View
//  Navigation sidebar with app branding and menu items

import SwiftUI
import UniformTypeIdentifiers

struct SidebarView: View {
    @Binding var selectedTab: Int
    @Namespace private var namespace
    
    // @AppStorage for reactive theme color updates
    @AppStorage("themeColor") private var themeColorValue: String = "red"
    
    @State private var todos: [TodoItem] = []
    @State private var newTodoTitle: String = ""
    @State private var newTodoMinutes: Int = 25
    @State private var isAddingTodo: Bool = false
    @State private var editingTodoId: UUID? = nil
    @State private var editingText: String = ""
    @State private var editingMinutes: Int = 25
    @State private var draggingItem: TodoItem?
    @State private var showCompletedTasks: Bool = false
    
    // MARK: - Computed Properties
    // Convert string theme color to SwiftUI Color
    private var accentColor: Color {
        switch themeColorValue {
        case "red": return .red
        case "blue": return .blue
        case "green": return .green
        case "orange": return .orange
        case "purple": return .purple
        default: return .red
        }
    }
    
    private var settings: SettingsStore {
        SettingsStore.shared
    }
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            // App Header
            appHeader
            
            // Navigation Items
            navigationItems
            
            // Todo List Section
            todoSection
            
            Spacer()
            
            // Mini Player shortcut
            miniPlayerButton
            
            // Version indicator
            versionIndicator
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            VisualEffectView(material: .sidebar, blendingMode: .behindWindow)
                .ignoresSafeArea()
        )
        .onAppear {
            loadTodos()
            NotificationCenter.default.addObserver(
                forName: .tasksDidChange,
                object: nil,
                queue: .main
            ) { _ in
                self.todos = self.settings.todos
            }
        }
    }
    
    private func loadTodos() {
        todos = settings.todos
    }
    
    private func saveTodos() {
        settings.todos = todos
        NotificationCenter.default.post(name: .tasksDidChange, object: nil)
    }
    
    private func saveTodosWithoutNotification() {
        settings.todos = todos
    }
    
    private func saveTodosAndNotify() {
        settings.todos = todos
        NotificationCenter.default.post(name: .tasksDidChange, object: nil)
    }
    
    private func addTodo() {
        guard !newTodoTitle.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let todo = TodoItem(title: newTodoTitle.trimmingCharacters(in: .whitespaces), requiredMinutes: newTodoMinutes)
        todos.insert(todo, at: 0)
        saveTodos()
        newTodoTitle = ""
        newTodoMinutes = 25
        isAddingTodo = false
    }
    
    private func toggleTodo(_ todo: TodoItem) {
        if let index = todos.firstIndex(where: { $0.id == todo.id }) {
            todos[index].isCompleted.toggle()
            saveTodos()
        }
    }
    
    private func deleteTodo(_ todo: TodoItem) {
        todos.removeAll { $0.id == todo.id }
        saveTodos()
    }
    
    private func startEditing(_ todo: TodoItem) {
        editingTodoId = todo.id
        editingText = todo.title
        editingMinutes = todo.requiredMinutes
    }
    
    private func saveEdit() {
        guard let id = editingTodoId else { return }
        if let index = todos.firstIndex(where: { $0.id == id }) {
            let trimmedText = editingText.trimmingCharacters(in: .whitespaces)
            if !trimmedText.isEmpty {
                todos[index].title = trimmedText
                todos[index].requiredMinutes = editingMinutes
                saveTodos()
            }
        }
        editingTodoId = nil
        editingText = ""
        editingMinutes = 25
    }
    
    private func cancelEdit() {
        editingTodoId = nil
        editingText = ""
    }
    
    private func moveTodoUp(_ todo: TodoItem) {
        guard let index = todos.firstIndex(where: { $0.id == todo.id }), index > 0 else { return }
        todos.move(fromOffsets: IndexSet(integer: index), toOffset: index - 1)
        saveTodos()
    }
    
    private func moveTodoDown(_ todo: TodoItem) {
        guard let index = todos.firstIndex(where: { $0.id == todo.id }), index < todos.count - 1 else { return }
        todos.move(fromOffsets: IndexSet(integer: index), toOffset: index + 2)
        saveTodos()
    }
    
    // MARK: - View Components
    private var appHeader: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                // App icon with gradient
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(accentColor.gradient)
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: "timer")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Text("Tempo")
                    .font(.system(size: 18, weight: .bold))
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 20)
        }
        .padding(.bottom, 8)
    }
    
    private var navigationItems: some View {
        VStack(spacing: 4) {
            SidebarItem(
                title: "Timer",
                icon: "timer",
                isSelected: selectedTab == 0,
                accentColor: accentColor,
                namespace: namespace
            )
            .onTapGesture { selectTab(0) }
            
            SidebarItem(
                title: "Statistics",
                icon: "chart.bar.fill",
                isSelected: selectedTab == 1,
                accentColor: accentColor,
                namespace: namespace
            )
            .onTapGesture { selectTab(1) }
            
            SidebarItem(
                title: "Settings",
                icon: "gearshape.fill",
                isSelected: selectedTab == 2,
                accentColor: accentColor,
                namespace: namespace
            )
            .onTapGesture { selectTab(2) }
            
            SidebarItem(
                title: "Help & About",
                icon: "questionmark.circle.fill",
                isSelected: selectedTab == 3,
                accentColor: accentColor,
                namespace: namespace
            )
            .onTapGesture { selectTab(3) }
        }
        .padding(.horizontal, 10)
        .padding(.top, 8)
    }
    
    private var todoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Section header
            HStack {
                Text("Tasks")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                
                Spacer()
                
                if !settings.activeTasks.isEmpty {
                    Text(settings.totalTaskTimeText)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(4)
                }
                
                Button(action: { isAddingTodo.toggle() }) {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 12))
                        .foregroundColor(accentColor)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 8)
            .padding(.top, 16)
            .onAppear {
                todos = settings.todos
            }
            
            // Add todo field
            if isAddingTodo {
                VStack(spacing: 6) {
                    TextField("Add task...", text: $newTodoTitle)
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(.system(size: 12))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(4)
                        .onSubmit { addTodo() }
                    
                    HStack(spacing: 6) {
                        Text("Time:")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        
                        Picker("", selection: $newTodoMinutes) {
                            Text("None").tag(0)
                            Text("15m").tag(15)
                            Text("25m").tag(25)
                            Text("30m").tag(30)
                            Text("45m").tag(45)
                            Text("50m").tag(50)
                            Text("1h").tag(60)
                            Text("1.5h").tag(90)
                            Text("2h").tag(120)
                        }
                        .pickerStyle(MenuPickerStyle())
                        .labelsHidden()
                        
                        Spacer()
                        
                        Button(action: addTodo) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .background(accentColor)
                                .clipShape(Circle())
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 6)
            }
            
            // Todo list with reordering
            let activeTodos = todos.filter { !$0.isCompleted }
            let currentTaskIndex = settings.currentTaskIndex
            let currentTask: TodoItem? = currentTaskIndex < activeTodos.count ? activeTodos[currentTaskIndex] : nil
            
            ScrollView {
                LazyVStack(spacing: 4) {
                    // Current task section
                    if let task = currentTask {
                        HStack(spacing: 6) {
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(accentColor)
                            Text("Current")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(accentColor)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 14)
                        .padding(.top, 8)
                        .padding(.bottom, 4)
                        
                        TodoRow(
                            todo: task,
                            accentColor: accentColor,
                            isEditing: editingTodoId == task.id,
                            editingText: editingText,
                            editingMinutes: editingMinutes,
                            showMoveButtons: true,
                            onToggle: { toggleTodo(task) },
                            onDelete: { deleteTodo(task) },
                            onEdit: { startEditing(task) },
                            onSaveEdit: { saveEdit() },
                            onCancelEdit: { cancelEdit() },
                            onEditingTextChange: { editingText = $0 },
                            onEditingMinutesChange: { editingMinutes = $0 },
                            onMoveUp: nil,
                            onMoveDown: nil
                        )
                        .onDrag {
                            draggingItem = task
                            return NSItemProvider(object: task.id.uuidString as NSString)
                        }
                        .onDrop(of: [.text], delegate: TodoDropDelegate(
                            item: task,
                            items: $todos,
                            draggingItem: $draggingItem,
                            accentColor: accentColor,
                            onSave: saveTodos
                        ))
                        
                        if activeTodos.count > 1 {
                            HStack(spacing: 6) {
                                Image(systemName: "line.3.horizontal")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                                Text("Up Next")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 14)
                            .padding(.top, 8)
                            .padding(.bottom, 4)
                        }
                    }
                    
                    // Other tasks
                    ForEach(activeTodos.filter { $0.id != currentTask?.id }) { todo in
                        TodoRow(
                            todo: todo,
                            accentColor: accentColor,
                            isEditing: editingTodoId == todo.id,
                            editingText: editingText,
                            editingMinutes: editingMinutes,
                            showMoveButtons: true,
                            onToggle: { toggleTodo(todo) },
                            onDelete: { deleteTodo(todo) },
                            onEdit: { startEditing(todo) },
                            onSaveEdit: { saveEdit() },
                            onCancelEdit: { cancelEdit() },
                            onEditingTextChange: { editingText = $0 },
                            onEditingMinutesChange: { editingMinutes = $0 },
                            onMoveUp: nil,
                            onMoveDown: nil
                        )
                        .onDrag {
                            draggingItem = todo
                            return NSItemProvider(object: todo.id.uuidString as NSString)
                        }
                        .onDrop(of: [.text], delegate: TodoDropDelegate(
                            item: todo,
                            items: $todos,
                            draggingItem: $draggingItem,
                            accentColor: accentColor,
                            onSave: saveTodos
                        ))
                    }
                }
                .padding(.horizontal, 12)
            }
            .frame(maxHeight: 220)
            
            let completedTodos = todos.filter { $0.isCompleted }
            
            if completedTodos.count > 0 {
                DisclosureGroup(isExpanded: $showCompletedTasks) {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(completedTodos) { task in
                            HStack(spacing: 8) {
                                Button(action: { toggleTodo(task) }) {
                                    Image(systemName: "arrow.uturn.backward.circle")
                                        .font(.system(size: 12))
                                        .foregroundColor(.blue.opacity(0.7))
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                Text(task.title)
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                    .strikethrough()
                                    .lineLimit(1)
                                
                                Spacer()
                                
                                Text(task.requiredTimeText)
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary.opacity(0.7))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(4)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.gray.opacity(0.05))
                            .cornerRadius(6)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                .padding(.horizontal, 6)
                    .padding(.vertical, 8)
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: completedTodos.count)
                } label: {
                    HStack {
                        Text("Completed")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                        
                        Spacer()
                        
                        Text("\(completedTodos.count)")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(4)
                        
                        Button(action: {
                            settings.deleteCompletedTasks()
                            todos = settings.todos
                        }) {
                            Image(systemName: "trash")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary.opacity(0.7))
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Image(systemName: showCompletedTasks ? "chevron.up" : "chevron.down")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.secondary)
                            .animation(.easeInOut(duration: 0.2), value: showCompletedTasks)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showCompletedTasks)
            }
        }
    }
    
    private var miniPlayerButton: some View {
        Button(action: {
            NotificationCenter.default.post(name: .openMiniPlayer, object: nil)
        }) {
            HStack(spacing: 8) {
                Image(systemName: "rectangle.compress.vertical")
                    .font(.system(size: 12, weight: .medium))
                Text("Mini Player")
                    .font(.system(size: 12, weight: .medium))
                Spacer()
                Text("⌘M")
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            .foregroundColor(.secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.gray.opacity(0.08))
            .cornerRadius(6)
        }
        .buttonStyle(PlainButtonStyle())
        .keyboardShortcut("m", modifiers: .command)
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
    }
    
    private var versionIndicator: some View {
        HStack {
            Circle()
                .fill(accentColor)
                .frame(width: 6, height: 6)
                .shadow(color: accentColor.opacity(0.5), radius: 2)
            
            Text("v1.2.3")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
    
    // MARK: - Helper Methods
    private func selectTab(_ index: Int) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            selectedTab = index
        }
    }
}

// MARK: - Todo Row
struct TodoRow: View {
    let todo: TodoItem
    let accentColor: Color
    let isEditing: Bool
    let editingText: String
    let editingMinutes: Int
    let showMoveButtons: Bool
    let onToggle: () -> Void
    let onDelete: () -> Void
    let onEdit: () -> Void
    let onSaveEdit: () -> Void
    let onCancelEdit: () -> Void
    let onEditingTextChange: (String) -> Void
    let onEditingMinutesChange: (Int) -> Void
    let onMoveUp: (() -> Void)?
    let onMoveDown: (() -> Void)?
    
    init(
        todo: TodoItem,
        accentColor: Color,
        isEditing: Bool,
        editingText: String,
        editingMinutes: Int,
        showMoveButtons: Bool = false,
        onToggle: @escaping () -> Void,
        onDelete: @escaping () -> Void,
        onEdit: @escaping () -> Void,
        onSaveEdit: @escaping () -> Void,
        onCancelEdit: @escaping () -> Void,
        onEditingTextChange: @escaping (String) -> Void,
        onEditingMinutesChange: @escaping (Int) -> Void,
        onMoveUp: (() -> Void)? = nil,
        onMoveDown: (() -> Void)? = nil
    ) {
        self.todo = todo
        self.accentColor = accentColor
        self.isEditing = isEditing
        self.editingText = editingText
        self.editingMinutes = editingMinutes
        self.showMoveButtons = showMoveButtons
        self.onToggle = onToggle
        self.onDelete = onDelete
        self.onEdit = onEdit
        self.onSaveEdit = onSaveEdit
        self.onCancelEdit = onCancelEdit
        self.onEditingTextChange = onEditingTextChange
        self.onEditingMinutesChange = onEditingMinutesChange
        self.onMoveUp = onMoveUp
        self.onMoveDown = onMoveDown
    }
    
    var body: some View {
        HStack(spacing: 8) {
            if showMoveButtons {
                VStack(spacing: 2) {
                    Button(action: { onMoveUp?() }) {
                        Image(systemName: "chevron.up")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .opacity(onMoveUp != nil ? 0.5 : 0)
                    
                    Button(action: { onMoveDown?() }) {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .opacity(onMoveDown != nil ? 0.5 : 0)
                }
                .frame(width: 16)
            }
            
            Button(action: onToggle) {
                Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 14))
                    .foregroundColor(todo.isCompleted ? accentColor : .gray)
            }
            .buttonStyle(PlainButtonStyle())
            
            if isEditing {
                VStack(alignment: .leading, spacing: 4) {
                    TextField("Edit task...", text: Binding(
                        get: { editingText },
                        set: { onEditingTextChange($0) }
                    ))
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(.system(size: 12))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(4)
                    .onSubmit { onSaveEdit() }
                    
                    HStack(spacing: 4) {
                        Text("Time:")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                        
                        Picker("", selection: Binding(
                            get: { editingMinutes },
                            set: { onEditingMinutesChange($0) }
                        )) {
                            Text("None").tag(0)
                            Text("15m").tag(15)
                            Text("25m").tag(25)
                            Text("30m").tag(30)
                            Text("45m").tag(45)
                            Text("50m").tag(50)
                            Text("1h").tag(60)
                            Text("1.5h").tag(90)
                            Text("2h").tag(120)
                        }
                        .pickerStyle(MenuPickerStyle())
                        .labelsHidden()
                    }
                }
                
                Button(action: onSaveEdit) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(4)
                        .background(accentColor)
                        .clipShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: onCancelEdit) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                VStack(alignment: .leading, spacing: 2) {
                    Text(todo.title)
                        .font(.system(size: 12))
                        .foregroundColor(todo.isCompleted ? .secondary : .primary)
                        .strikethrough(todo.isCompleted)
                        .lineLimit(1)
                        .onTapGesture(count: 2) {
                            onEdit()
                        }
                    
                    Text(todo.requiredTimeText)
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: onDelete) {
                    Image(systemName: "xmark")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.secondary)
                        .opacity(0.5)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 6)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(6)
    }
}

// MARK: - Todo Drop Delegate
struct TodoDropDelegate: DropDelegate {
    let item: TodoItem
    @Binding var items: [TodoItem]
    @Binding var draggingItem: TodoItem?
    let accentColor: Color
    let onSave: () -> Void
    
    func performDrop(info: DropInfo) -> Bool {
        draggingItem = nil
        onSave()
        return true
    }
    
    func dropEntered(info: DropInfo) {
        guard let draggingItem = draggingItem,
              draggingItem.id != item.id else {
            return
        }
        
        guard let fromIndex = items.firstIndex(where: { $0.id == draggingItem.id }),
              let toIndex = items.firstIndex(where: { $0.id == item.id }) else {
            return
        }
        
        if fromIndex != toIndex {
            withAnimation(.interactiveSpring(response: 0.25, dampingFraction: 0.8)) {
                items.move(fromOffsets: IndexSet(integer: fromIndex), toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex)
            }
        }
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }
}

// MARK: - Sidebar Item
struct SidebarItem: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let accentColor: Color
    let namespace: Namespace.ID
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .frame(width: 20)
                .foregroundColor(isSelected ? .white : .secondary)
            
            Text(title)
                .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
                .foregroundColor(isSelected ? .white : .primary)
            
            Spacer()
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(
            Group {
                if isSelected {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(accentColor)
                        .matchedGeometryEffect(id: "tab", in: namespace)
                }
            }
        )
        .contentShape(Rectangle())
    }
}

// MARK: - Visual Effect View
/// NSViewRepresentable for applying macOS visual effect materials
struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}
