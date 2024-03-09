import Foundation
import Primitives

let globalHook = Lock()

@main
enum Program {
    static func main() async throws {

        DispatchQueue.global().async { 
            while !ThreadPool.globalPool.isBusyExecuting {}
            print("Busy \(ThreadPool.globalPool.isBusyExecuting)")
        }

        replaceGlobalConcurrencyHook()

        try await Task.sleep(for: .milliseconds(900))

        do {

            let thread = UniqueThread(name: "Thread") {
                for i in 1 ... 5 {
                    print("Thread doing \(i)")
                    Thread.sleep(forTimeInterval: 0.4)
                }
            }

            thread.start()

            thread.join()
        }

        let queue = Queue<Int>(order: .firstOut)

        print("Count ", queue.length)

        print("Empty ", queue.isEmpty)

        queue <- 1000

        print("Count ", queue.length)

        print("Empty ", queue.isEmpty)

        if let value = <-queue {
            print("Hello, world! ", value)
        }

        if let value = <-queue {
            print("Hello, world! ", value)
        }

        print("Count ", queue.length)

        print("Empty ", queue.isEmpty)

        _ = consume queue

        let specialActorInstance = SpecialActor()

        let specialInstance = SpecialThreadActor()

        let lockInstance = LockActor()

        let priorities = [TaskPriority.background, .high, .medium, .low, .userInitiated, .utility]

        do {
            var counter = 0

            let rwLock = Lock()

            var counterUsingLocked = 0

            let pool = ThreadPool(count: 4)!

             var array: [Int] = Array(repeating: 0, count: 10)

            for i in 1 ... 10 {
                pool.submit {
                    counterUsingLocked += i
                    rwLock.whileLocked {
                        counter += i
                    }
                    rwLock.whileLocked {
                        array[i - 1] = i
                    }
                }
            }

            print("Pool busy: \(pool.isBusyExecuting)")

            pool.pollAll()

            rwLock.whileLocked {
                print("Counter \(counter)")
            }
            print("Counter using @Locked property wrapper \(counterUsingLocked)")

            print("Got \(array.count) items in the array")

            print(pool)
        }

        async let _ = withDiscardingTaskGroup { group in
            for priority in priorities {
                group.addTask(priority: priority) {
                    async let _ = specialActorInstance.increment(by: Int.random(in: 1 ... 10))
                    async let _ = specialInstance.increment(by: Int.random(in: 1 ... 10))
                    async let _ = lockInstance.increment(by: Int.random(in: 1 ... 10))
                    Once.runOnce {
                        print("\(Task.currentPriority)")
                    }
                }
            }
        }

        await Task.yield()

        specialActorInstance.pollAll()
        ThreadPool.globalPool.pollAll()

        for _ in 1 ... 8 {
            ThreadPool.globalPool.submit {
                Thread.sleep(forTimeInterval: 1)
                print("\(Thread.current.name ?? "unknown")")
            }
        }

        print("ThreadPool.globalPool busy: \(ThreadPool.globalPool.isBusyExecuting)")

        print("Count for \(type(of: specialActorInstance)): \(await specialActorInstance.count)")
        print("Count for \(type(of: specialInstance)): \(await specialInstance.count)")
        print("Count for \(type(of: lockInstance)): \(await lockInstance.count)")

    }
}
