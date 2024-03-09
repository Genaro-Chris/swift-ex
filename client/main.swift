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

print("Connected to server \(server)")

Task.detached {
    await SignalHandler.start(with: .SIGINT, .SIGQUIT, .SIGTSTP) { signal in
        try? await client.close(server: server)
        exit(1)
    }
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
                id != client.id
            }[input]
            let newclient = try Client.resolve(
                id: newId,
                using: client.actorSystem)
            let newid = try await newclient.print_id()
            print("New Client got back \(newid)")

        default:
            let list = try await server.prung_id()
                .filter { id in
                    id != client.id
                }
            for (index, id) in list.enumerated() {
                debugPrint("Index \(index)", id)
                do {
                    let newactor = try Client.resolve(id: id, using: client.actorSystem)
                    try await newactor.execute { id in
                        print("About to work on the \(newactor) side")
                        print("\(id)")

                    }
                } catch let error as HTTPActorSystemError {
                    switch error {

                        case .actorNotFound(id): print("No actor found with id \(id)")

                        default: print("Other error")

                    }
                } catch {
                    print("Failed with \(error)")
                }
            }
    }

}
