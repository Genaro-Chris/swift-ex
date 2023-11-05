import Distributed
import DistributedHTTPActorSystem

typealias DefaultDistributedActorSystem = HTTPActorSystem

public distributed actor Server: ServerActor {

    distributed public func remove_with_id(id: HTTPActorSystem.ActorID) async throws {
        remove_id(id: id)
    }

    public distributed func allClients() -> [HTTPActorSystem.ActorID] {
        self.clients.keys.reduce(into: []) {
            $0.append($1)
        }
    }

    func remove_id(id: HTTPActorSystem.ActorID) {
        if case .some(_) = self.clients.removeValue(forKey: id) {
            print("\(id) just left")
        }
    }

    fileprivate var clients: [HTTPActorSystem.ActorID: any SpecialActor] = [:]

    public distributed func prung() async -> [String] {
        return self.clients.keys.reduce(into: []) { acc, x in
            acc.append(x.description)
        }
    }

    public distributed func prung_id() async -> [ID] {
        return self.clients.keys.reduce(into: []) { acc, x in
            acc.append(x)
        }
    }

    public init() throws {
        self.actorSystem = try HTTPActorSystem(
            host: "localhost", port: 80, group: .init(numberOfThreads: 8), logLevel: .info)
    }

    public nonisolated var unownedExecutor: UnownedSerialExecutor {
        CustomExecutor.sharedDistributedUnownedExecutor
    }

    public distributed func join_with_id<T: SpecialActor>(
        id: T.ID, _ with: T? = nil
    ) throws where T.ActorSystem == HTTPActorSystem, T.ActorSystem == HTTPActorSystem {
        let actor = try T.resolve(id: .random(host: id.host, port: id.port, path: id.path), using: self.actorSystem)
        self.clients.updateValue(actor, forKey: id)
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
