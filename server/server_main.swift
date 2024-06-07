import Foundation
import SignalHandler
import shared

@main
enum Main {
    static func main() async throws {
        let server = try Server()
        try server.actorSystem.host("/Server") {
            server
        }

        async let _ = SignalHandler.start(with: .SIGINT, .SIGQUIT, .SIGTSTP) { _ in
            let clients = try? await server.allClientsID()
            await withDiscardingTaskGroup { group in
                for id in clients! {
                    let item = try? Client.resolve(id: id, using: server.actorSystem)
                    // try? await server.remove_with_id(id: id)
                    group.addTask {
                        #if swift(<6) && compiler(<6)
                            try? await item?.execute { id in
                                try await print("Port: \(item?.port ?? 0)")
                                print("\(id) disconnected")
                            }
                        #endif
                        try? await item?.close(server: server)

                    }

                }
            }

            exit(1)
        }

        while true {
            guard readLine() != nil else {
                break
            }
            /* try await server.allClientsID().forEach { id in
                print("\(id)")
                try await Client.resolve(id: id, using: server.actorSystem).health_check()
            } */
            for id in try await server.allClientsID() {
                print("\(id)")
                try await Client.resolve(id: id, using: server.actorSystem).health_check()
            }
        }
    }
}

extension Array where Element: Sendable {

    @usableFromInline
    nonisolated func forEach(body: (Element) async throws -> Void) async rethrows {
        for item in self {
            try await body(item)
        }
    }
}
