import Vapor
import FluentMongoDriver

final class AddressResponse: Content {
    var id: ObjectId?
    var street: String
    var city: String
    var zip: String
    var userId: ObjectId
    var createdAt: Date?
    var updatedAt: Date?
    var deletedAt: Date?
    
    init(_ address: Address) {
        self.id = address.id
        self.street = address.street
        self.city = address.city
        self.zip = address.zip
        self.userId = address.userId
        self.createdAt = address.createdAt
        self.updatedAt = address.updatedAt
        self.deletedAt = address.deletedAt
    }
}
