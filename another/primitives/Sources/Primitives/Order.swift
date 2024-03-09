/// Order for dequeuing item from a `Queue` instance
public enum Order: Sendable {
    /// First-In First out order
    case firstOut
    /// Last-In Last-Out order
    case lastOut
}
