import Foundation

extension TaskGroup {

    mutating func addTask<T: Sendable>(
        priority: TaskPriority? = nil, operation: @escaping @Sendable (T) async -> ChildTaskResult,
        value: @autoclosure @escaping () -> T
    ) {
        self.addTask(priority: priority) {
            await operation(value())
        }
    }
}

extension ThrowingTaskGroup {

    mutating func addTask<T: Sendable>(
        priority: TaskPriority? = nil, operation: @escaping @Sendable (T) async -> ChildTaskResult,
        value: @autoclosure @escaping () -> T
    ) {
        self.addTask(priority: priority) {
            await operation(value())
        }
    }
}

extension ThrowingDiscardingTaskGroup {

    mutating func addTask<T: Sendable>(
        priority: TaskPriority? = nil, value: @autoclosure @escaping () -> T,
        operation: @escaping @Sendable (T) async -> Void
    ) {
        self.addTask(priority: priority) {
            await operation(value())
        }
    }
}

extension DiscardingTaskGroup {

    mutating func addTask<T: Sendable>(
        priority: TaskPriority? = nil, value: @autoclosure @escaping () -> T,
        operation: @escaping @Sendable (T) async -> Void
    ) {
        self.addTask(priority: priority) {
            await operation(value())
        }
    }
}
