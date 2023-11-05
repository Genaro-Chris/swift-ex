import CustomExecutor
import Distributed
import DistributedHTTPActorSystem
import Foundation
import SignalHandler

let client = try Client()

Task.detached {
    try client.actorSystem.host("/Client") {
        client
    }
}

let server = try Server.resolve(
    id: .random(host: "localhost", port: 80, path: "/Server"), using: client.actorSystem)

async let _ = SignalHandler.start(with: .SIGINT, .SIGQUIT, .SIGTSTP) { _ in
    try? await client.close(server: server)
    exit(1)

}

try await server.join_with_id(id: client.actorId, client)

print("List of other clients of connected")

while let input = readLine() {
    switch input {
        case "exit", "Exit":
            try await client.close(server: server)
            break
        case "interact":
            guard let input = Int(readLine() ?? "0") else {
                continue
            }
            let newId = try await server.prung_id().filter { id in
                try await id != client.actorId
            }[input]
            let newclient = try Client.resolve(
                id: newId,
                using: client.actorSystem)
            let newid = try await newclient.print_id()
            print("New Client got back \(newid)")

        default:
            let list = try await server.prung()
                .filter { id in
                    try await id.description != client.actorId.description
                }
            if list.count > 1 {
                for (index, id) in list.enumerated() {
                    debugPrint("Index \(index)", id)
                }
            }
    }

}

extension Array {

    @usableFromInline
    func filter(body: (Element) async throws -> Bool) async rethrows -> Self {
        var newarr: Self = []
        for item in self where try await body(item) {
            newarr.append(item)
        }
        return newarr
    }
}
