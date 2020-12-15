import Vapor
import JWT

extension AnyHashable {
    static let payload: String = "jwt_payload"
}

extension Request {
    var loggedIn: Bool {
        return self.storage[PayloadKey.self] != nil ? true : false
    }

    var payload: Payload {
        get { self.storage[PayloadKey.self]! }
        set { self.storage[PayloadKey.self] = newValue }
    }

}

