import Foundation

class Buffer<Element> {

    var buffer: ContiguousArray<Element>

    var count: Int {
        self.buffer.count
    }

    var isEmpty: Bool {
        self.buffer.isEmpty
    }

    init() {
        self.buffer = ContiguousArray()
    }

    func enqueue(_ item: Element) {
        self.buffer.append(item)
    }

    func dequeue(order: Order) -> Element? {
        guard !self.buffer.isEmpty else {
            return nil
        }
        switch order {
            case .firstOut:
                return self.buffer.removeFirst()
            case .lastOut:
                return self.buffer.popLast()
        }
    }

    func clear() {
        self.buffer.removeAll()
    }
}
