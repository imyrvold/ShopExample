import Fluent
import Vapor
import SendGrid

func routes(_ app: Application, _ sendgridClient: SendGridClient) throws {
    let root = app.grouped(.anything, "users")
    let auth = root.grouped(UserAuthenticator())
    
    root.get("health") { req in
        return "All good!"
    }
    
    try auth.grouped("addresses").register(collection: AddressController())
    try root.register(collection: AuthController(sendGridClient: sendgridClient))
    try auth.register(collection: UsersController())
}
