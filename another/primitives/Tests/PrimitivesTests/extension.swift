import Foundation
import Primitives

extension Queue: Sequence, IteratorProtocol {
    public func next() -> Element? {
        self.dequeue()
    }
}
