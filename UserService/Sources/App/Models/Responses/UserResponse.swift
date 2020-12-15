import Vapor
import FluentMongoDriver

struct UserResponse: Content {
    let id: ObjectId?
    let firstname, lastname: String?
    let email: String
    let addresses: [AddressResponse]?

    init(user: User, addresses: [AddressResponse]? = nil) {
        self.id = user.id
        self.firstname = user.firstname
        self.lastname = user.lastname
        self.email = user.email
        self.addresses = addresses
    }
}
