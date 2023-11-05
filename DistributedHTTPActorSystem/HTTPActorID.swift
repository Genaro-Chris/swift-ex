import Foundation

extension HTTPActorSystem {
    public struct ActorID: Sendable, Codable, Hashable, CustomStringConvertible {
        let `protocol`: String
        public var host: String
        public var port: Int
        public let path: String
        let uuid: UUID

        public static func random(host: String, port: Int, path: String) -> ActorID {
            return .init(host: host, port: port, path: path)
        }

        public init(host: String, port: Int, path: String, uuid: UUID = UUID()) {
            self.`protocol` = "http"
            self.host = host
            self.port = port
            self.path = path
            self.uuid = uuid
        }

        var uri: String {
            if path == "/" {
                return "\(`protocol`)://\(host):\(port)/\(uuid)"
            }
            return "\(`protocol`)://\(host):\(port)/\(path)/\(uuid)"
        }

        public var description: String {
            "\(path)#\(uuid)"
        }
    }
}
