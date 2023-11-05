import Foundation
import Distributed
import NIO

enum HTTPActorSystemError: DistributedActorSystemError {
  // Resolve errors
  case actorNotFound(HTTPActorSystem.ActorID)

  // Invocation decoding errors
  case unexpectedNumberOfArguments(known: Int, required: Int)

  // Response errors
  case unableToDecodeResponse(body: ByteBuffer, expectedType: Any.Type, error: Error)
  case missingResponsePayload(expected: Any.Type)
  case badStatusCode(code: UInt)
}