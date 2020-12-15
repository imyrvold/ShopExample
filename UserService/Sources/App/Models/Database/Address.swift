import Vapor
import Fluent
import FluentMongoDriver

final class Address: Model {
    static let schema = "addresses"
    
    @ID(custom: .id)
    var id: ObjectId?

    @Field(key: .street)
    var street: String
    
    @Field(key: .city)
    var city: String
    
    @Field(key: .zip)
    var zip: String
    
    @Timestamp(key: .createdAt, on: .create)
    var createdAt: Date?
    
    @Timestamp(key: .updatedAt, on: .update)
    var updatedAt: Date?

    @Timestamp(key: .deletedAt, on: .delete)
    var deletedAt: Date?

    @Field(key: .userId)
    var userId: ObjectId
    
    init() {}
    
    init(street: String, city: String, zip: String, userId: ObjectId) {
        self.street = street
        self.city = city
        self.zip = zip
        self.userId = userId
    }
}

extension FieldKey {
    static var street: Self { "street" }
    static var city: Self { "city" }
    static var zip: Self { "zip" }
    static var userId: Self { "userId" }
}
