import Vapor
import Fluent
import FluentMongoDriver
import JWT

struct RefreshToken: JWTPayload {
    let id: ObjectId
    let iat: ExpirationClaim
    let exp: ExpirationClaim
    
    init(user: User, expiration: TimeInterval = Constants.REFRESH_TOKEN_LIFETIME) {
        let now = Date().timeIntervalSince1970

        self.id = user.id ?? ObjectId()
        self.iat = ExpirationClaim(value: Date().addingTimeInterval(now))
        self.exp = ExpirationClaim(value: Date().addingTimeInterval(expiration))
    }
    
    func verify(using signer: JWTSigner) throws {
        try self.exp.verifyNotExpired()
    }
}
