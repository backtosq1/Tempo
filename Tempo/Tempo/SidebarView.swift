//  Tempo - Sidebar View
//  Navigation sidebar with app branding and menu items

import SwiftUI

struct SidebarView: View {
    @Binding var selectedTab: Int
    @Namespace private var namespace
    @ObservedObject private var updateManager = UpdateManager.shared
    
    // @AppStorage for reactive theme color updates
    @AppStorage("themeColor") private var themeColorValue: String = "red"
    
    @State private var todos: [TodoItem] = []
    @State private var newTodoTitle: String = ""
    @State private var isAddingTodo: Bool = false
    @State private var editingTodoId: UUID? = nil
    @State private var editingText: String = ""
    
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
        }
    }
    
    private func loadTodos() {
        todos = settings.todos
    }
    
    private func saveTodos() {
        settings.todos = todos
    }
    
    private func addTodo() {
        guard !newTodoTitle.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let todo = TodoItem(title: newTodoTitle.trimmingCharacters(in: .whitespaces))
        todos.insert(todo, at: 0)
        saveTodos()
        newTodoTitle = ""
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
                
                Button(action: { isAddingTodo.toggle() }) {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 12))
                        .foregroundColor(accentColor)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            
            // Add todo field
            if isAddingTodo {
                HStack(spacing: 6) {
                    TextField("Add task...", text: $newTodoTitle)
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(.system(size: 12))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(4)
                        .onSubmit { addTodo() }
                    
                    Button(action: addTodo) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(6)
                            .background(accentColor)
                            .clipShape(Circle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 12)
            }
            
            // Todo list
            ScrollView {
                VStack(spacing: 4) {
                    ForEach(todos.prefix(5)) { todo in
                        TodoRow(
                            todo: todo,
                            accentColor: accentColor,
                            isEditing: editingTodoId == todo.id,
                            editingText: editingText,
                            onToggle: { toggleTodo(todo) },
                            onDelete: { deleteTodo(todo) },
                            onEdit: { startEditing(todo) },
                            onSaveEdit: { saveEdit() },
                            onCancelEdit: { cancelEdit() },
                            onEditingTextChange: { editingText = $0 }
                        )
                    }
                }
                .padding(.horizontal, 12)
            }
            .frame(maxHeight: 150)
            
            if todos.count > 5 {
                Text("+\(todos.count - 5) more")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 16)
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
            
            Text("v\(updateManager.currentVersion)")
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
    let onToggle: () -> Void
    let onDelete: () -> Void
    let onEdit: () -> Void
    let onSaveEdit: () -> Void
    let onCancelEdit: () -> Void
    let onEditingTextChange: (String) -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            Button(action: onToggle) {
                Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 14))
                    .foregroundColor(todo.isCompleted ? accentColor : .gray)
            }
            .buttonStyle(PlainButtonStyle())
            
            if isEditing {
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
                Text(todo.title)
                    .font(.system(size: 12))
                    .foregroundColor(todo.isCompleted ? .secondary : .primary)
                    .strikethrough(todo.isCompleted)
                    .lineLimit(1)
                    .onTapGesture(count: 2) {
                        onEdit()
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
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(6)
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
