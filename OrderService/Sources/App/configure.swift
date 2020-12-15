import Fluent
import FluentMongoDriver
import Vapor

// configures your application
public func configure(_ app: Application) throws {
    // MARK: JWT
    if app.environment != .testing {
        let jwksFilePath = app.directory.workingDirectory + (Environment.get("JWKS_KEYPAIR_FILE") ?? "keypair.jwks")
         guard
             let jwks = FileManager.default.contents(atPath: jwksFilePath),
             let jwksString = String(data: jwks, encoding: .utf8)
             else {
                 fatalError("Failed to load JWKS Keypair file at: \(jwksFilePath)")
         }
         try app.jwt.signers.use(jwksJSON: jwksString)
    }

    // MARK: Database
    
    guard let connectionString = Environment.get("MONGODB") else {
        fatalError("No MongoDB connection string is available in .env")
    }

    app.databases.use(try .mongo(connectionString: connectionString), as: .mongo)
    
    // MARK: App Config
    app.config = .environment
        
    try routes(app)
    try migrations(app)
    try services(app)

    try app.autoMigrate().wait()

}
