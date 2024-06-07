@_implementationOnly import Distributed
@_private(sourceFile:"HTTPActorSystem.swift") import DistributedHTTPActorSystem

public distributed actor Client: SpecialActor {

    let _port = Int.random(in: 7000...9000)

    public distributed var port: Int {
        get async { _port }
    }

    public distributed var actorId: ID {
        self.id
    }

    // Compiler generated
    // @_compilerInitialized nonisolated final public let id: DistributedHTTPActorSystem.HTTPActorSystem.ActorID

    /*
        @available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
        @_semantics("defaultActor") nonisolated final public var unownedExecutor: _Concurrency.UnownedSerialExecutor {
            get
        }
     */

    public init() throws {
        self.actorSystem = try DefaultDistributedActorSystem(
            host: "localhost", port: _port, group: .singletonMultiThreadedEventLoopGroup,
            logLevel: .critical)
    }

    public distributed func print_id() -> ID {
        print("ID: \(self.id)")
        return self.id
    }

    public distributed func close<T: ServerActor & Codable>(server: T? = nil) async throws {
        try await server?.remove_with_id(id: self.actorId as! T.ID)

    }

    public func executeBody(body: (ID) -> Void) {
        body(self.id)
    }

    public distributed func health_check() {
        print("Health check for \(self.id)")
    }
}
