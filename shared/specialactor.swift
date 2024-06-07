@_implementationOnly import Distributed
/* public */ import DistributedHTTPActorSystem
import Foundation

@dynamicMemberLookup
public protocol SpecialActor: DistributedActor, Codable {
    subscript<T: Sendable>(dynamicMember member: ReferenceWritableKeyPath<Self, T>) -> T { get set }
}

extension SpecialActor {
    public subscript<T: Sendable>(dynamicMember member: ReferenceWritableKeyPath<Self, T>) -> T {
        get {
            print("Called get")
            return self[keyPath: member]
        }
        set {
            print("Called set")
            self[keyPath: member] = newValue
        }
        _modify {
            print("Called modify and about to yield")
            yield &self[keyPath: member]
            print("Yielded already")
        }
    }

    public distributed func health_check() {
        print("Health check for \(self.id)")
    }

    #if swift(<6) && compiler(<6)
        public distributed func execute(body: (ID) -> Void) {
            body(self.id)
        }
    #endif
}

public protocol ServerActor: DistributedActor {
    distributed func remove_with_id(
        id: Self.ID
    ) async throws
}
