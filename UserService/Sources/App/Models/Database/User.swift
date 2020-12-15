import Vapor
import Fluent
import FluentMongoDriver

final class User: Model {
    static let schema = "users"

    init() {}
    
    @ID(custom: .id)
    var id: ObjectId?
    
    @Field(key: .firstname)
    var firstname: String?
    
    @Field(key: .lastname)
    var lastname: String?
    
    @Field(key: .email)
    var email: String
    
    @Field(key: .password)
    var password: String
    
    @Timestamp(key: .createdAt, on: .create)
    var createdAt: Date?
    
    @Timestamp(key: .updatedAt, on: .update)
    var updatedAt: Date?

    @Timestamp(key: .deletedAt, on: .delete)
    var deletedAt: Date?
    
    init(_ email: String, _ firstName: String? = nil, _ lastName: String? = nil, _ password: String) throws {
        self.email = email
        self.firstname = firstName
        self.lastname = lastName
        self.password = try BCryptDigest().hash(password)
    }
}

extension FieldKey {
    static var firstname: Self { "firstname" }
    static var lastname: Self { "lastname" }
    static var email: Self { "email" }
    static var password: Self { "password" }
    static var createdAt: Self { "createdAt" }
    static var updatedAt: Self { "updatedAt" }
    static var deletedAt: Self { "deletedAt" }
}
