import Vapor
import Fluent

final class UsersController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        routes.get("profile", use: profile)
        routes.patch("profile", use: save)
        routes.delete("user", use: delete)
    } 
    
    func profile(_ request: Request) throws -> EventLoopFuture<UserSuccessResponse> {
        let payload = try request.auth.require(Payload.self)

        return User.query(on: request.db).filter(\.$id == payload.id).all().flatMap { users in
            guard users.count > 0, let user = users.first else {
                return request.eventLoop.makeFailedFuture(Abort(.unauthorized))
            }

            return request.eventLoop.makeSucceededFuture(UserSuccessResponse(user: UserResponse(user: user)))
        }
    }
    
    func save(_ request: Request) throws -> EventLoopFuture<UserSuccessResponse> {
        let payload = try request.auth.require(Payload.self)
        let content = try request.content.decode(EditUserInput.self)
        
        return User.query(on: request.db).filter(\.$id == payload.id).first().flatMap { user in
            guard let user = user else { return request.eventLoop.makeFailedFuture(Abort(.internalServerError)) }
            if let firstname = content.firstname {
                user.firstname = firstname
            }
            if let lastname = content.lastname {
                user.lastname = lastname
            }
            return user.update(on: request.db).map { _ in
                return UserSuccessResponse(user: UserResponse(user: user))
            }
        }
    }
    
    func delete(_ request: Request) throws -> EventLoopFuture<HTTPStatus> {
        let payload = try request.auth.require(Payload.self)

        return User.query(on: request.db).filter(\.$id == payload.id).first().flatMap { user in
            guard let user = user, let userId = user.id else { return request.eventLoop.makeFailedFuture(Abort(.badRequest, reason: "No user found!")) }
            return Address.query(on: request.db).filter(\.$userId == userId).delete().flatMap {
                return user.delete(on: request.db).transform(to: .ok)
            }
        }
    }
}
