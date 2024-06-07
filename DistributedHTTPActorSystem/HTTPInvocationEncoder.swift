import Foundation

public struct HTTPInvocationEncoder: DistributedTargetInvocationEncoder {
    public typealias SerializationRequirement = Codable

    var genericSubstitutions: [String] = []
    var arguments: [Data] = []
    var throwing = false
    var errorValue = ""
    var returnValue = ""

    let encoder: JSONEncoder

    /// This serialization mode is a bit simplistic, but good enough for our sample
    public init(encoder: JSONEncoder) {
        self.encoder = encoder
    }

    public mutating func recordGenericSubstitution<T>(_ type: T.Type) throws {
        if let name = _mangledTypeName(T.self) {
            genericSubstitutions.append(name)
        }
    }

    public mutating func recordArgument<Value: Codable>(_ argument: RemoteCallArgument<Value>)
        throws
    {
        let encoded = try encoder.encode(argument.value)
        self.arguments.append(encoded)
    }

    public mutating func recordErrorType<E: Error>(_ type: E.Type) throws {
        self.throwing = true
        if let name = _mangledTypeName(E.self) {
            self.errorValue = name
        }
    }

    public mutating func recordReturnType<R: SerializationRequirement>(_ type: R.Type) throws {
        if let name = _mangledTypeName(R.self) {
            returnValue = name
        }
    }

    public mutating func doneRecording() throws {
        // ignore
    }

    func makeEnvelope(
        recipient: HTTPActorSystem.ActorID,
        target: RemoteCallTarget,
        callID: HTTPActorSystem.CallID
    ) throws -> RemoteCallEnvelope {
        try RemoteCallEnvelope(
            recipient: recipient,
            target: target.identifier,
            callID: callID,
            arguments: arguments,
            genericSubstitutions: self.genericSubstitutions,
            returnValue: returnValue)
    }
}
