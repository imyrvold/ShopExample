import Vapor
import Fluent
import FluentMongoDriver
import JWT
import SendGrid

final class AuthController: RouteCollection {
    private let sendGridClient: SendGridClient
    
    init(sendGridClient: SendGridClient) {
        self.sendGridClient = sendGridClient
    }
    
    func boot(routes: RoutesBuilder) throws {
        routes.post("register", use: register)
        routes.post("login", use: login)
        routes.post("accessToken", use: refreshAccessToken)
    }
    
    func register(_ request: Request) throws -> EventLoopFuture<UserSuccessResponse> {
        let userInput = try request.content.decode(NewUserInput.self)
        let user = try User(userInput.email, userInput.firstname, userInput.lastname, userInput.password)

        return User.query(on: request.db).filter(\.$email == user.email).count().flatMap { all in
            if all > 0 {
                return request.eventLoop.makeFailedFuture(Abort(.badRequest, reason: "This email is already registered."))
            }

            return user.save(on: request.db).transform(to: user)
                .map { user in
                    return UserSuccessResponse(user: UserResponse(user: user))
                }
                .flatMap { userResponse in
                    let subject = "Your Registration"
                    let body = "Welcome!"
                    let name = [user.firstname, user.lastname].compactMap { $0 }.joined(separator: " ")
                    let from = EmailAddress(email: "info@domain.com", name: nil)
                    let address = EmailAddress(email: user.email, name: name)
                    let header = Personalization(to: [address], subject: subject)
                    let email = SendGridEmail(personalizations: [header], from: from, subject: subject, content: [[ "type": "text", "value": body]])

                    return self.sendGridClient.send([email], on: request.eventLoop).transform(to: userResponse)
                }
        }
    }
    
    func login(_ request: Request) throws -> EventLoopFuture<LoginResponse> {
        let data = try request.content.decode(LoginInput.self)

        return User.query(on: request.db).filter(\.$email == data.email).all().flatMap { users in
            guard users.count > 0, let user = users.first, let userId = user.id else {
                return request.eventLoop.makeFailedFuture(Abort(.unauthorized))
            }

            var check = false
            do {
                check = try Bcrypt.verify(data.password, created: user.password)
            } catch {}
            if check {
                let userPayload = Payload(id: userId, email: user.email)
                do {
                    let accessToken = try request.application.jwt.signers.sign(userPayload)
                    let refreshPayload = RefreshToken(user: user)
                    let refreshToken = try request.application.jwt.signers.sign(refreshPayload)
                    let userResponse = UserResponse(user: user)
                    
                    return user.save(on: request.db).transform(to: LoginResponse(accessToken: accessToken, refreshToken: refreshToken, user: userResponse))
                } catch {
                    return request.eventLoop.makeFailedFuture(Abort(.internalServerError))
                }
            } else {
                return request.eventLoop.makeFailedFuture(Abort(.unauthorized))
            }
        }
    }
    
    func refreshAccessToken(_ request: Request) throws -> EventLoopFuture<RefreshTokenResponse> {
        let data = try request.content.decode(RefreshTokenInput.self)
        let refreshToken = data.refreshToken
        let jwtPayload = try request.application.jwt.signers.verify(refreshToken, as: RefreshToken.self)
        
        let userID = jwtPayload.id
        
        return User.query(on: request.db).filter(\.$id == userID).all().flatMap { users in
            guard users.count > 0, let user = users.first, let userId = user.id else {
                return request.eventLoop.makeFailedFuture(Abort(.badRequest, reason: "No user found."))
            }
            let payload = Payload(id: userId, email: user.email)
            var payloadString = ""
            do {
                payloadString = try request.application.jwt.signers.sign(payload)
            } catch{}
            
            return user.save(on: request.db).map { _ in
                return RefreshTokenResponse(accessToken: payloadString)
            }
        }
    }
}
