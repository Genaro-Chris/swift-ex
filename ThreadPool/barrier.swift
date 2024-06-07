import Foundation

///
public class Barrier: @unchecked Sendable {
    private let condition = Condition()
    private let mutex = Mutex()
    private var blockedThreadIndex = 0
    private let threadCount: Int

    /// 
    /// - Parameter value: 
    public init?(value: Int) {
        if value < 1 {
            return nil
        }
        threadCount = value
    }

    ///
    public func arriveAndWait() {
        mutex.whileLocked {
            blockedThreadIndex += 1
            guard blockedThreadIndex != threadCount else {
                blockedThreadIndex = 0
                condition.broadcast()
                return
            }
            condition.wait(mutex: mutex, condition: blockedThreadIndex == 0)
        }
    }
}

/* 
public final class Barrier {

    let condition: Condition

    let mutex: Mutex

    var blockedThreadsCount: Int

    let threadsCount: Int

    // Flag to differentiate barrier generations (avoid race conditions)
    var generation: Bool

    public init(size: Int) {
        if size < 1 {
            fatalError("Cannot initialize an instance of Barrier with count less than 1")
        }
        condition = Condition()
        mutex = Mutex()
        blockedThreadsCount = 0
        threadsCount = size
        generation = false
    }


    public func arriveAndWait() {
        mutex.whileLocked {
            let currentGeneration = generation
            blockedThreadsCount += 1
            guard blockedThreadsCount != threadsCount else {
                blockedThreadsCount = 0
                generation = !generation
                condition.broadcast()
                return
            }
            /* while currentGeneration == generation && blockedThreadsCount < threadsCount {
                condition.wait(mutex: mutex)
            } */
            condition.wait(mutex: mutex, condition: !(currentGeneration == generation && blockedThreadsCount < threadsCount))
        }
    }
} */