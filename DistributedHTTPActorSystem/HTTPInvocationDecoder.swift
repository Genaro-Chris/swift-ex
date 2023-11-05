import Foundation
import NIO

public struct HTTPInvocationResultHandler: DistributedTargetInvocationResultHandler {
    public typealias SerializationRequirement = Codable

    let callID: HTTPActorSystem.CallID
    let system: HTTPActorSystem
    let replyPromise: EventLoopPromise<Data>

    public init(
        system: HTTPActorSystem,
        callID: HTTPActorSystem.CallID,
        replyPromise: EventLoopPromise<Data>
    ) {
        self.system = system
        self.callID = callID
        self.replyPromise = replyPromise
    }

    public func onReturnVoid() async throws {
        system.log.trace("onReturnVoid", metadata: ["callID": "\(callID)"])
        let encoder = JSONEncoder()
        encoder.userInfo[.actorSystemKey] = system

        do {
            let data = try encoder.encode(_Done())
            replyPromise.succeed(data)
        } catch {
            replyPromise.fail(error)
        }
    }

    public func onReturn<Success: Codable>(value: Success) async throws {
        system.log.trace("onReturn: \(value)", metadata: ["callID": "\(callID)"])

        let encoder = JSONEncoder()
        encoder.userInfo[.actorSystemKey] = system

        do {
            let data = try encoder.encode(value)
            replyPromise.succeed(data)
        } catch {
            replyPromise.fail(error)
        }
    }

    public func onThrow<Err: Error>(error: Err) async throws {
        system.log.trace("onThrow: \(error)", metadata: ["callID": "\(callID)"])

        let encoder = JSONEncoder()
        encoder.userInfo[.actorSystemKey] = system

        replyPromise.fail(error)
    }
}

public struct HTTPInvocationDecoder: DistributedTargetInvocationDecoder {
    public typealias SerializationRequirement = Codable

    let decoder: JSONDecoder
    let envelope: RemoteCallEnvelope
    var argIndex = 0

    public init(decoder: JSONDecoder, envelope: RemoteCallEnvelope) {
        self.decoder = decoder
        self.envelope = envelope
    }

    public mutating func decodeGenericSubstitutions() throws -> [Any.Type] {
        return envelope.genericSubstitutions.compactMap { name in
            _typeByName(name)
        }
    }

    public mutating func decodeNextArgument<Argument: SerializationRequirement>() throws -> Argument
    {
        guard envelope.arguments.count > argIndex else {
            throw HTTPActorSystemError.unexpectedNumberOfArguments(
                known: envelope.arguments.count, required: argIndex + 1)
        }
        let data = envelope.arguments[argIndex]
        argIndex += 1
        return try self.decoder.decode(Argument.self, from: data)
    }

    public mutating func decodeErrorType() throws -> Any.Type? {
        _typeByName(envelope.errorValue)
    }

    public mutating func decodeReturnType() throws -> Any.Type? {
        _typeByName(envelope.returnValue)
    }
}
