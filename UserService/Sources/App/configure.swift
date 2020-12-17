import Fluent
import FluentMongoDriver
import Vapor
import JWT
import SendGrid

// configures your application
public func configure(_ app: Application) throws {
    // MARK: JWT
    print("configure 1")
    guard let jwksString = Environment.get("JWKS_KEYPAIR") else {
        fatalError("No value was found at the given public key environment 'JWKS_KEYPAIR'")
    }
    print("configure 2")
    try app.jwt.signers.use(jwksJSON: jwksString)
    print("configure 3")

    app.middleware.use(CORSMiddleware())
    app.middleware.use(ErrorMiddleware() { request, error in
        struct ErrorResponse: Content {
            var error: String
        }
        let data: Data?
        do {
            data = try JSONEncoder().encode(ErrorResponse(error: "\(error)"))
        }
        catch {
            data = "{\"error\":\"\(error)\"}".data(using: .utf8)
        }
        let res = Response(status: .internalServerError, body: Response.Body(data: data!))
        res.headers.replaceOrAdd(name: .contentType, value: "application/json")
        return res
    })

    // MARK: SendGrid
    guard let sendgridApiKey = Environment.get("SENDGRID_API_KEY") else {
        fatalError("No value was found at the given public key environment 'SENDGRID_API_KEY'")
    }
    let sendgridClient = SendGridClient(client: app.client, apiKey: sendgridApiKey)
    
    // MARK: Database
    
    guard let connectionString = Environment.get("MONGODB") else {
        fatalError("No MongoDB connection string is available in .env")
    }

    app.databases.use(try .mongo(connectionString: connectionString), as: .mongo)
    
    // MARK: App Config
//    app.config = .environment
    
    app.migrations.add(CreateUser())
    app.migrations.add(CreateAddress())
        
    try routes(app, sendgridClient)
    print("configure 4")

//    try app.autoMigrate().wait()

}
