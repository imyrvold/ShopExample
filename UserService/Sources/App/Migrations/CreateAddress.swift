import Fluent
import FluentMongoDriver

struct CreateAddress: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(Address.schema)
            .id()
            .field(.userId, .uuid, .references(User.schema, "id"))
            .field(.street, .string, .required)
            .field(.zip, .string, .required)
            .field(.city, .string, .required)
            .field(.createdAt, .datetime)
            .field(.updatedAt, .datetime)
            .field(.deletedAt, .datetime)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(Address.schema).delete()
    }
}
