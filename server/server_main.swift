import CustomExecutor
import SignalHandler

@main
enum Main {
    static func main() async throws {
        let server = try Server()
        Task.detached {
            try server.actorSystem.host("/Server") {
                server
            }
        }

        async let _ = SignalHandler.start(with: .SIGINT, .SIGQUIT, .SIGTSTP) { _ in
            let clients = try? await server.allClients()
            for id in clients! {
                let item = try? Client.resolve(id: id, using: server.actorSystem)
                try? await item?.execute { id in
                    Task {
                        try await print("Port: \(item?.port ?? 0)")
                    }
                    print("\(id) disconnected")
                }
            }
            exit(1)
        }

        while true {
            guard readLine() != nil else {
                break
            }
            try await print(server.allClients())
        }
    }
}

extension Array {

    @usableFromInline
    func forEach(body: (Element) async throws -> Void) async rethrows {
        for item in self {
            try await body(item)
        }
    }
}
