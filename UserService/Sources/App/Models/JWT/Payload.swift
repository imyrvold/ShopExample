import Vapor
import JWT
import FluentMongoDriver

struct Payload: JWTPayload, Authenticatable {
    // User-releated stuff
    var id: ObjectId
    var firstname: String?
    var lastname: String?
    var email: String
    
    // JWT stuff
    var exp: ExpirationClaim
    
    func verify(using signer: JWTSigner) throws {
        try self.exp.verifyNotExpired()
    }
    
    init(id: ObjectId, email: String) {
        self.id = id
        self.firstname = nil
        self.lastname = nil
        self.email = email
        self.exp = ExpirationClaim(value: Date().addingTimeInterval(Constants.ACCESS_TOKEN_LIFETIME))
    }
}

struct PayloadKey: StorageKey {
    typealias Value = Payload
}
