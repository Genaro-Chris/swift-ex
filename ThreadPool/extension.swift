extension ThreadSafeQueue: Sequence, IteratorProtocol {

    public func next() -> Element? {
        <-self
    }
}
