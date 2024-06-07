@_implementationOnly import Distributed
import DistributedHTTPActorSystem

public typealias DefaultDistributedActorSystem = HTTPActorSystem

public typealias ID = DefaultDistributedActorSystem.ActorID

public distributed actor Server: ServerActor {

    distributed public func remove_with_id(id: ID) async throws {
        remove_id(id: id)
    }

    public distributed func allClientsID() -> [ID] {
        self.clients.keys.reduce(into: []) {
            $0.append($1)
        }
    }

    func remove_id(id: ID) {
        if case .some(_) = self.clients.removeValue(forKey: id) {
            print("\(id) just left")
        }
    }

    fileprivate var clients: [ID: any SpecialActor] = [:]

    public distributed func prung_id() async -> [ID] {
        return self.clients.keys.reduce(into: []) { acc, x in
            acc.append(x)
        }
    }

    public init() throws {
        self.actorSystem = try HTTPActorSystem(
            host: "localhost", port: 80, group: .init(numberOfThreads: 8), logLevel: .critical)
    }

    public distributed func join_with_id<T: SpecialActor>(
        id: T.ID, _ with: T? = nil
    ) throws where T.ActorSystem == HTTPActorSystem, T.ActorSystem == HTTPActorSystem {
        guard let with else {
            let actor = try T.resolve(
                id: .random(host: id.host, port: id.port, path: id.path), using: self.actorSystem)
            self.clients.updateValue(actor, forKey: id)
            return
        }
        self.clients.updateValue(with, forKey: id)
    }

    public distributed func welcome(id: ID) {
        print("\(id) just joined")
    }
}

extension Dictionary {

    @usableFromInline
    func forEach(body: (Element) async throws -> Void) async rethrows {
        for item in self {
            try await body(item)
        }
    }
}
