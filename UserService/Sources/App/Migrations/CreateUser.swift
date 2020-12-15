import Fluent
import FluentMongoDriver

struct CreateUser: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("users")
            .id()
            .field(.firstname, .string)
            .field(.lastname, .string)
            .field(.email, .string, .required)
            .field(.password, .string, .required)
            .field(.createdAt, .datetime)
            .field(.updatedAt, .datetime)
            .field(.deletedAt, .datetime)
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(User.schema).delete()
    }
}
