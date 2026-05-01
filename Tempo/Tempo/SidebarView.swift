//  Tempo - Sidebar View
//  Navigation sidebar with app branding and menu items

import SwiftUI
import UniformTypeIdentifiers

struct SidebarView: View {
    @Binding var selectedTab: Int
    @EnvironmentObject var timerManager: TimerManager
    @Namespace private var namespace
    @ObservedObject private var updateManager = UpdateManager.shared
    
    // @AppStorage for reactive theme color updates
    @AppStorage(SettingsKeys.Appearance.themeColor.rawValue) private var themeColorValue: String = "red"
    @AppStorage(SettingsKeys.Appearance.appTheme.rawValue) private var appTheme: String = "default"
    @ObservedObject private var locManager = LocalizationManager.shared
    
    @State private var todos: [TodoItem] = []
    @State private var newTodoTitle: String = ""
    @State private var isAddingTodo: Bool = false
    @State private var editingTodoId: UUID? = nil
    @State private var editingText: String = ""
    @State private var newTodoPriority: Priority = .medium
    @State private var newTodoDueDate: Date? = nil
    @State private var showDatePicker: Bool = false

    @State private var showTaskHint: Bool = false
    @State private var draggingTodo: TodoItem? = nil
    @State private var showCompleted: Bool = false
    
    @State private var todoSortOrder: TodoSortOrder = .importance

    private var incompleteTodos: [TodoItem] {
        let filtered = todos.filter { !$0.isCompleted }
        switch todoSortOrder {
        case .importance:
            return filtered.sorted { $0.priority > $1.priority }
        case .dueDate:
            return filtered.sorted { todo1, todo2 in
                guard let date1 = todo1.dueDate else { return false }
                guard let date2 = todo2.dueDate else { return true }
                return date1 < date2
            }
        }
    }

    private var completedTodos: [TodoItem] {
        todos.filter { $0.isCompleted }
    }

    private var accentColor: Color { themeColorValue.themeColor }
    private var theme: ThemeColors { ThemeManager.colors(for: appTheme, accent: accentColor) }
    private var currentTheme: AppTheme { AppTheme(rawValue: appTheme) ?? .default }
    
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
            Group {
                if currentTheme == .default {
                    VisualEffectView(material: .sidebar, blendingMode: .behindWindow)
                        .ignoresSafeArea()
                } else {
                    theme.background.ignoresSafeArea()
                }
            }
        )
        .onAppear {
            loadTodos()
            todoSortOrder = settings.todoSortOrder
        }
    }
    
    private func loadTodos() {
        todos = settings.todos
        todoSortOrder = settings.todoSortOrder
    }
    
    private func saveTodos() {
        settings.todos = todos
        settings.todoSortOrder = todoSortOrder
        timerManager.reloadTodos()
    }
    
    private func addTodo() {
        guard !newTodoTitle.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let todo = TodoItem(title: newTodoTitle.trimmingCharacters(in: .whitespaces), priority: newTodoPriority, dueDate: newTodoDueDate)
        withAnimation(.spring(response: 0.5, dampingFraction: 0.65)) {
            todos.insert(todo, at: 0)
        }
        saveTodos()
        newTodoTitle = ""
        newTodoPriority = .medium
        newTodoDueDate = nil
        showDatePicker = false

        // Delay dismissing the add field slightly for better visual flow
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                isAddingTodo = false
            }
        }
    }
    
    private func toggleTodo(_ todo: TodoItem) {
        if let index = todos.firstIndex(where: { $0.id == todo.id }) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.68)) {
                todos[index].isCompleted.toggle()
            }
            if todos[index].isCompleted && timerManager.activeTaskId == todo.id {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                    timerManager.setActiveTask(nil)
                }
            }
            saveTodos()
        }
    }
    
    private func deleteTodo(_ todo: TodoItem) {
        if timerManager.activeTaskId == todo.id {
            timerManager.setActiveTask(nil)
        }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            todos.removeAll { $0.id == todo.id }
        }
        saveTodos()
    }
    
    private func startEditing(_ todo: TodoItem) {
        editingTodoId = todo.id
        editingText = todo.title
    }
    
    private func saveEdit() {
        guard let id = editingTodoId else { return }
        if let index = todos.firstIndex(where: { $0.id == id }) {
            let trimmedText = editingText.trimmingCharacters(in: .whitespaces)
            if !trimmedText.isEmpty {
                todos[index].title = trimmedText
                saveTodos()
            }
        }
        editingTodoId = nil
        editingText = ""
    }
    
    private func cancelEdit() {
        editingTodoId = nil
        editingText = ""
    }

    private func clearCompleted() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            todos.removeAll { $0.isCompleted }
        }
        saveTodos()
    }

    private func changePriority(_ todo: TodoItem, to priority: Priority) {
        if let index = todos.firstIndex(where: { $0.id == todo.id }) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                todos[index].priority = priority
            }
            saveTodos()
        }
    }

    private func changeDueDate(_ todo: TodoItem, to date: Date?) {
        if let index = todos.firstIndex(where: { $0.id == todo.id }) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                todos[index].dueDate = date
            }
            saveTodos()
        }
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
                        .shadow(color: accentColor.opacity(0.4 * theme.glowIntensity), radius: 4 * theme.glowIntensity)

                    Image(systemName: "timer")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Text("Tempo")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(theme.textPrimary)
                
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
                title: L("sidebar.timer"),
                icon: "timer",
                isSelected: selectedTab == 0,
                accentColor: accentColor,
                namespace: namespace,
                themeColors: theme
            )
            .onTapGesture { selectTab(0) }

            SidebarItem(
                title: L("sidebar.insights"),
                icon: "brain.head.profile",
                isSelected: selectedTab == 1,
                accentColor: accentColor,
                namespace: namespace,
                themeColors: theme
            )
            .onTapGesture { selectTab(1) }

            SidebarItem(
                title: L("sidebar.statistics"),
                icon: "chart.bar.fill",
                isSelected: selectedTab == 2,
                accentColor: accentColor,
                namespace: namespace,
                themeColors: theme
            )
            .onTapGesture { selectTab(2) }

            SidebarItem(
                title: L("sidebar.settings"),
                icon: "gearshape.fill",
                isSelected: selectedTab == 3,
                accentColor: accentColor,
                namespace: namespace,
                themeColors: theme
            )
            .onTapGesture { selectTab(3) }

            SidebarItem(
                title: L("sidebar.helpAbout"),
                icon: "questionmark.circle.fill",
                isSelected: selectedTab == 4,
                accentColor: accentColor,
                namespace: namespace,
                themeColors: theme
            )
            .onTapGesture { selectTab(4) }
        }
        .padding(.horizontal, 10)
        .padding(.top, 8)
        .frame(maxWidth: .infinity)
    }

    private var todoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Section header with count
            HStack {
                Text(L("sidebar.tasks"))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(theme.textSecondary)
                    .textCase(.uppercase)

                if !incompleteTodos.isEmpty {
                    Text("\(incompleteTodos.count)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 18, height: 18)
                        .background(accentColor)
                        .clipShape(Circle())
                        .shadow(color: accentColor.opacity(0.4), radius: 4)
                        .scaleEffect(1.0)
                        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: incompleteTodos.count)
                        .transition(.scale.combined(with: .opacity))
                }

                Spacer()
                
                Menu {
                    Button(action: { todoSortOrder = .importance }) {
                        Label(L("sidebar.tasks.sortByPriority"), systemImage: todoSortOrder == .importance ? "checkmark" : "")
                    }
                    Button(action: { todoSortOrder = .dueDate }) {
                        Label(L("sidebar.tasks.sortByDate"), systemImage: todoSortOrder == .dueDate ? "checkmark" : "")
                    }
                } label: {
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.system(size: 10))
                        .foregroundColor(theme.textSecondary.opacity(0.6))
                }
                .menuStyle(.borderlessButton)
                .frame(width: 20)

                Button(action: { showTaskHint.toggle() }) {
                    Image(systemName: "questionmark.circle")
                        .font(.system(size: 11))
                        .foregroundColor(theme.textSecondary.opacity(0.5))
                }
                .buttonStyle(PlainButtonStyle())
                .popover(isPresented: $showTaskHint, arrowEdge: .bottom) {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 8) {
                            Image(systemName: "cursorarrow")
                                .font(.system(size: 12))
                                .frame(width: 16)
                            Text(L("sidebar.tasks.hint.click"))
                                .font(.system(size: 12))
                        }
                        HStack(spacing: 8) {
                            Image(systemName: "cursorarrow.motionlines")
                                .font(.system(size: 12))
                                .frame(width: 16)
                            Text(L("sidebar.tasks.hint.rightClick"))
                                .font(.system(size: 12))
                        }
                    }
                    .padding(14)
                }

                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isAddingTodo.toggle()
                    }
                }) {
                    Image(systemName: isAddingTodo ? "xmark.circle" : "plus.circle")
                        .font(.system(size: 12))
                        .foregroundColor(isAddingTodo ? .secondary : accentColor)
                        .shadow(color: accentColor.opacity(0.3 * theme.glowIntensity), radius: 3 * theme.glowIntensity)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)

            // Add todo field
            if isAddingTodo {
                VStack(spacing: 8) {
                    // Priority picker with labels + due date toggle
                    HStack(spacing: 6) {
                        ForEach(Priority.allCases, id: \.self) { priority in
                            Button(action: { newTodoPriority = priority }) {
                                HStack(spacing: 3) {
                                    Circle()
                                        .fill(priority.color)
                                        .frame(width: 6, height: 6)
                                    Text(priority == .low ? L("sidebar.tasks.low") : priority == .medium ? L("sidebar.tasks.med") : L("sidebar.tasks.high"))
                                        .font(.system(size: 10, weight: newTodoPriority == priority ? .semibold : .regular))
                                        .fixedSize()
                                }
                                .padding(.horizontal, 7)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(newTodoPriority == priority ? priority.color.opacity(0.15) : Color.clear)
                                )
                                .overlay(
                                    Capsule()
                                        .stroke(newTodoPriority == priority ? priority.color.opacity(0.4) : Color.clear, lineWidth: 1)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }

                        Spacer()

                        // Due date toggle
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                showDatePicker.toggle()
                                if showDatePicker && newTodoDueDate == nil {
                                    newTodoDueDate = Date()
                                }
                                if !showDatePicker {
                                    newTodoDueDate = nil
                                }
                            }
                        }) {
                            Image(systemName: newTodoDueDate != nil ? "calendar.badge.checkmark" : "calendar")
                                .font(.system(size: 11))
                                .foregroundColor(newTodoDueDate != nil ? accentColor : .secondary)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }

                    // Date picker row
                    if showDatePicker {
                        HStack(spacing: 6) {
                            Image(systemName: "calendar")
                                .font(.system(size: 10))
                                .foregroundColor(accentColor)
                            DatePicker("", selection: Binding(
                                get: { newTodoDueDate ?? Date() },
                                set: { newTodoDueDate = $0 }
                            ), displayedComponents: .date)
                                .datePickerStyle(.compact)
                                .labelsHidden()
                                .font(.system(size: 11))

                            Spacer()

                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    newTodoDueDate = nil
                                    showDatePicker = false
                                }
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    HStack(spacing: 6) {
                        TextField(L("sidebar.tasks.addPlaceholder"), text: $newTodoTitle)
                            .textFieldStyle(PlainTextFieldStyle())
                            .font(.system(size: 12))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(6)
                            .onSubmit { addTodo() }
                            .onExitCommand {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    isAddingTodo = false
                                    newTodoTitle = ""
                                    newTodoPriority = .medium
                                    newTodoDueDate = nil
                                    showDatePicker = false
                                }
                            }

                        Button(action: addTodo) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 18))
                                .foregroundColor(newTodoTitle.trimmingCharacters(in: .whitespaces).isEmpty ? .gray : accentColor)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(newTodoTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
                .padding(.horizontal, 12)
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            // Todo list
            ScrollView {
                VStack(spacing: 4) {
                    if incompleteTodos.isEmpty && completedTodos.isEmpty {
                        // Empty state
                        VStack(spacing: 8) {
                            Image(systemName: "checklist")
                                .font(.system(size: 20))
                                .foregroundColor(theme.textSecondary.opacity(0.5))
                            Text(L("sidebar.tasks.noTasks"))
                                .font(.system(size: 12))
                                .foregroundColor(theme.textSecondary.opacity(0.6))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                    }

                    ForEach(incompleteTodos) { todo in
                        TodoRow(
                            todo: todo,
                            accentColor: accentColor,
                            themeColors: theme,
                            isEditing: editingTodoId == todo.id,
                            isActive: timerManager.activeTaskId == todo.id,
                            editingText: editingText,
                            onToggle: { toggleTodo(todo) },
                            onDelete: { deleteTodo(todo) },
                            onEdit: { startEditing(todo) },
                            onSaveEdit: { saveEdit() },
                            onCancelEdit: { cancelEdit() },
                            onEditingTextChange: { editingText = $0 },
                            onTapActive: {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                    if timerManager.activeTaskId == todo.id {
                                        timerManager.setActiveTask(nil)
                                    } else {
                                        timerManager.setActiveTask(todo.id)
                                    }
                                }
                            },
                            onChangePriority: { changePriority(todo, to: $0) },
                            onChangeDueDate: { changeDueDate(todo, to: $0) }
                        )
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.8, anchor: .top).combined(with: .opacity),
                            removal: .asymmetric(
                                insertion: .identity,
                                removal: .move(edge: .leading).combined(with: .opacity).combined(with: .scale(scale: 0.9))
                            )
                        ))
                        .opacity(draggingTodo?.id == todo.id ? 0.4 : 1)
                        .scaleEffect(draggingTodo?.id == todo.id ? 0.95 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: draggingTodo?.id == todo.id)
                        .onDrag {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                draggingTodo = todo
                            }
                            return NSItemProvider(object: todo.id.uuidString as NSString)
                        }
                        .onDrop(of: [.text], delegate: TodoDropDelegate(
                            item: todo,
                            todos: $todos,
                            draggingTodo: $draggingTodo,
                            onReorder: { saveTodos() }
                        ))
                    }

                    if !completedTodos.isEmpty {
                        // Collapsible completed header
                        HStack {
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    showCompleted.toggle()
                                }
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: showCompleted ? "chevron.down" : "chevron.right")
                                        .font(.system(size: 9, weight: .semibold))
                                    Text(L("sidebar.tasks.completed"))
                                        .font(.system(size: 11, weight: .medium))
                                    Text("\(completedTodos.count)")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(theme.textSecondary)
                                }
                                .foregroundColor(theme.textSecondary)
                            }
                            .buttonStyle(PlainButtonStyle())

                            Spacer()

                            if showCompleted {
                                Button(action: clearCompleted) {
                                    Text(L("sidebar.tasks.clear"))
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(.secondary)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .transition(.opacity)
                            }
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 4)

                        if showCompleted {
                            ForEach(completedTodos) { todo in
                                TodoRow(
                                    todo: todo,
                                    accentColor: accentColor,
                                    themeColors: theme,
                                    isEditing: editingTodoId == todo.id,
                                    isActive: false,
                                    editingText: editingText,
                                    onToggle: { toggleTodo(todo) },
                                    onDelete: { deleteTodo(todo) },
                                    onEdit: { startEditing(todo) },
                                    onSaveEdit: { saveEdit() },
                                    onCancelEdit: { cancelEdit() },
                                    onEditingTextChange: { editingText = $0 },
                                    onTapActive: {},
                                    onChangePriority: { changePriority(todo, to: $0) },
                                    onChangeDueDate: { changeDueDate(todo, to: $0) }
                                )
                                .transition(.asymmetric(
                                    insertion: .opacity,
                                    removal: .move(edge: .leading).combined(with: .opacity)
                                ))
                            }
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }
                    }
                }
                .padding(.horizontal, 12)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var miniPlayerButton: some View {
        Button(action: {
            NotificationCenter.default.post(name: .openMiniPlayer, object: nil)
        }) {
            HStack(spacing: 8) {
                Image(systemName: "rectangle.compress.vertical")
                    .font(.system(size: 12, weight: .medium))
                Text(L("sidebar.miniPlayer"))
                    .font(.system(size: 12, weight: .medium))
                Spacer()
                Text("\u{2318}M")
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundColor(theme.textSecondary)
            }
            .foregroundColor(theme.textSecondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(theme.cardBackground.opacity(0.5))
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
                .shadow(color: accentColor.opacity(0.5 * theme.glowIntensity), radius: 2 * theme.glowIntensity)
            
            Text("v\(updateManager.currentVersion)")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(theme.textSecondary)
            
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
    var themeColors: ThemeColors = .default
    let isEditing: Bool
    let isActive: Bool
    let editingText: String
    let onToggle: () -> Void
    let onDelete: () -> Void
    let onEdit: () -> Void
    let onSaveEdit: () -> Void
    let onCancelEdit: () -> Void
    let onEditingTextChange: (String) -> Void
    let onTapActive: () -> Void
    let onChangePriority: (Priority) -> Void
    let onChangeDueDate: (Date?) -> Void

    @State private var isHovered = false
    @State private var showDueDatePicker = false
    @State private var pulseAnimation = false

    private var dueDateColor: Color {
        guard let due = todo.dueDate else { return .secondary }
        let calendar = Calendar.current
        if calendar.isDateInToday(due) { return .orange }
        if due < Date() { return .red }
        return .secondary
    }

    private static let shortDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                // Active indicator bar with pulse
                if isActive && !todo.isCompleted {
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(accentColor)
                        .frame(width: 3)
                        .shadow(color: accentColor.opacity(pulseAnimation ? 0.6 : 0.3), radius: pulseAnimation ? 6 : 3)
                        .transition(.scale(scale: 0, anchor: .leading).combined(with: .opacity))
                        .onAppear {
                            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                                pulseAnimation = true
                            }
                        }
                }

                // Priority dot
                Circle()
                    .fill(todo.priority.color)
                    .frame(width: 8, height: 8)
                    .shadow(color: todo.priority.color.opacity(0.4), radius: 2)
                    .scaleEffect(isHovered ? 1.15 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isHovered)

                Button(action: onToggle) {
                    Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 14))
                        .foregroundColor(todo.isCompleted ? accentColor : .gray)
                        .scaleEffect(todo.isCompleted ? 1.0 : (isHovered ? 1.1 : 1.0))
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isHovered)
                        .animation(.spring(response: 0.4, dampingFraction: 0.5), value: todo.isCompleted)
                }
                .buttonStyle(PlainButtonStyle())

                if isEditing {
                    TextField(L("sidebar.tasks.editPlaceholder"), text: Binding(
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
                    .onExitCommand { onCancelEdit() }

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
                            .padding(.leading, 3)
                    }
                    .buttonStyle(PlainButtonStyle())
                } else {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(todo.title)
                            .font(.system(size: 12, weight: isActive && !todo.isCompleted ? .medium : .regular))
                            .foregroundColor(todo.isCompleted ? themeColors.textSecondary : themeColors.textPrimary)
                            .strikethrough(todo.isCompleted)
                            .lineLimit(1)

                        // Due date label
                        if let due = todo.dueDate, !todo.isCompleted {
                            HStack(spacing: 3) {
                                Image(systemName: "calendar")
                                    .font(.system(size: 8))
                                Text(Self.shortDateFormatter.string(from: due))
                                    .font(.system(size: 10))
                            }
                            .foregroundColor(dueDateColor)
                        }
                    }
                    .onTapGesture {
                        if !todo.isCompleted { onTapActive() }
                    }

                    // Session count badge
                    if todo.linkedSessionCount > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "timer")
                                .font(.system(size: 7))
                            Text("\(todo.linkedSessionCount)")
                                .font(.system(size: 9, weight: .semibold))
                        }
                        .foregroundColor(themeColors.textSecondary)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(Capsule().fill(Color.gray.opacity(0.15)))
                        .scaleEffect(1.0)
                        .animation(.spring(response: 0.4, dampingFraction: 0.65), value: todo.linkedSessionCount)
                        .transition(.scale.combined(with: .opacity))
                    }

                    Spacer()

                    // Hover-to-reveal menu button
                    if isHovered {
                        Menu {
                            Button(action: { showDueDatePicker.toggle() }) {
                                Label(todo.dueDate != nil ? L("sidebar.tasks.changeDueDate") : L("sidebar.tasks.setDueDate"), systemImage: "calendar")
                            }
                            if todo.dueDate != nil {
                                Button(role: .destructive, action: { onChangeDueDate(nil) }) {
                                    Label(L("sidebar.tasks.removeDueDate"), systemImage: "calendar.badge.minus")
                                }
                            }
                            Divider()
                            ForEach(Priority.allCases, id: \.self) { priority in
                                Button(action: { onChangePriority(priority) }) {
                                    HStack {
                                        Text(priority == .low ? L("sidebar.tasks.low") : priority == .medium ? L("sidebar.tasks.med") : L("sidebar.tasks.high"))
                                        if todo.priority == priority {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                            Divider()
                            Button(action: onEdit) {
                                Label(L("sidebar.tasks.edit"), systemImage: "pencil")
                            }
                            Button(role: .destructive, action: onDelete) {
                                Label(L("sidebar.tasks.delete"), systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(.secondary.opacity(0.5))
                                .frame(width: 20, height: 20)
                                .contentShape(Rectangle())
                        }
                        .menuStyle(.borderlessButton)
                        .menuIndicator(.hidden)
                        .fixedSize()
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.8).combined(with: .opacity),
                            removal: .scale(scale: 0.6).combined(with: .opacity)
                        ))
                    }
                }
            }

            // Inline date picker popover
            if showDueDatePicker {
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.system(size: 10))
                        .foregroundColor(accentColor)
                    DatePicker(
                        "",
                        selection: Binding(
                            get: { todo.dueDate ?? Date() },
                            set: { onChangeDueDate($0) }
                        ),
                        displayedComponents: .date
                    )
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .font(.system(size: 11))

                    Spacer()

                    Button(action: { showDueDatePicker = false }) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(accentColor)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.top, 4)
                .padding(.leading, isActive && !todo.isCompleted ? 19 : 16)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isActive && !todo.isCompleted
                    ? accentColor.opacity(0.08)
                    : themeColors.cardBackground.opacity(isHovered ? 0.5 : 0.3))
        )
        .cornerRadius(6)
        .scaleEffect(isHovered && !isEditing ? 1.01 : 1.0)
        .shadow(
            color: isActive && !todo.isCompleted ? accentColor.opacity(0.15) : .clear,
            radius: 4,
            y: 2
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showDueDatePicker)
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isActive)
        .onHover { hovering in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isHovered = hovering
            }
        }
        .contextMenu {
            Button(action: { showDueDatePicker.toggle() }) {
                Label(todo.dueDate != nil ? "Change Due Date" : "Set Due Date", systemImage: "calendar")
            }
            if todo.dueDate != nil {
                Button(role: .destructive, action: { onChangeDueDate(nil) }) {
                    Label("Remove Due Date", systemImage: "calendar.badge.minus")
                }
            }

            Divider()

            ForEach(Priority.allCases, id: \.self) { priority in
                Button(action: { onChangePriority(priority) }) {
                    HStack {
                        Text(priority.rawValue.capitalized)
                        if todo.priority == priority {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }

            Divider()

            Button(action: onEdit) {
                Label("Edit", systemImage: "pencil")
            }
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

// MARK: - Sidebar Item
struct SidebarItem: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let accentColor: Color
    let namespace: Namespace.ID
    var themeColors: ThemeColors = .default

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .frame(width: 20)
                .foregroundColor(isSelected ? .white : themeColors.textSecondary)
                .shadow(color: isSelected ? accentColor.opacity(0.4 * themeColors.glowIntensity) : .clear, radius: 4 * themeColors.glowIntensity)

            Text(title)
                .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
                .foregroundColor(isSelected ? .white : themeColors.textPrimary)

            Spacer()
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(
            Group {
                if isSelected {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(accentColor)
                        .shadow(color: accentColor.opacity(0.4 * themeColors.glowIntensity), radius: 6 * themeColors.glowIntensity, y: 2)
                        .matchedGeometryEffect(id: "tab", in: namespace)
                } else if themeColors.glowIntensity > 1.0 {
                    // Subtle accent-tinted background for high-glow themes (Neon)
                    RoundedRectangle(cornerRadius: 8)
                        .fill(accentColor.opacity(0.08))
                }
            }
        )
        .contentShape(Rectangle())
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Todo Drop Delegate

struct TodoDropDelegate: DropDelegate {
    let item: TodoItem
    @Binding var todos: [TodoItem]
    @Binding var draggingTodo: TodoItem?
    let onReorder: () -> Void

    func performDrop(info: DropInfo) -> Bool {
        draggingTodo = nil
        onReorder()
        return true
    }

    func dropEntered(info: DropInfo) {
        guard let dragging = draggingTodo,
              dragging.id != item.id,
              let fromIndex = todos.firstIndex(where: { $0.id == dragging.id }),
              let toIndex = todos.firstIndex(where: { $0.id == item.id }) else { return }

        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            todos.move(fromOffsets: IndexSet(integer: fromIndex), toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex)
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
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
