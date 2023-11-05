import Distributed
import DistributedHTTPActorSystem

public distributed actor Client: SpecialActor {

    public typealias ActorSystem = HTTPActorSystem
    let _port = Int.random(in: 7000 ... 9000)

    public distributed var port: Int {
        _port
    }

    public distributed var actorId: HTTPActorSystem.ActorID {
        self.id
    }

    public init() throws {
        self.actorSystem = try HTTPActorSystem(host: "localhost", port: _port, group: .singletonMultiThreadedEventLoopGroup, logLevel: .critical)
    }

    public distributed func print_id() -> ID {
        print("ID: \(self.id)")
        return self.id
    }

    public distributed func close<T: ServerActor & Codable>(server: T? = nil) async throws {
        try await server?.remove_with_id(id: self.actorId as! T.ID)

    }

}
