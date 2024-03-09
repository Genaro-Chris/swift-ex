/// Provides a way for ending a `ThreadPool` or `SingleThread` types
public enum WaitType: Sendable {
    /// Cancels all tasks that's doesn't wait for anything
    case cancelAll
    /// Waits for all tasks to finish their execution
    case waitForAll
}
