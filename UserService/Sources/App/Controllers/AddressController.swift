import Vapor
import Fluent
import FluentMongoDriver

final class AddressController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        routes.get(use: addresses)
        routes.post(use: create)
        routes.patch(":id", use: update)
        routes.delete(":id", use: delete)
    }
    
    func addresses(_ request: Request) throws -> EventLoopFuture<[AddressResponse]> {
        return Address.query(on: request.db).filter(\.$userId == request.payload.id).all().map { addresses in
            return addresses.map { AddressResponse($0) }
        }
    }
    
    func create(_ request: Request) throws -> EventLoopFuture<AddressResponse> {
        let content = try request.content.decode(AddressInput.self)
        let address = Address(street: content.street, city: content.city, zip: content.zip, userId: request.payload.id)
        
        return address.save(on: request.db).map { _ in
            return AddressResponse(address)
        }
    }
    
    func update(_ request: Request) throws -> EventLoopFuture<AddressResponse> {
        let content = try request.content.decode(AddressInput.self)
        let id = ObjectId(request.parameters.get("id") ?? "") ?? ObjectId()

        return Address.query(on: request.db).filter(\.$id == id).filter(\.$userId == request.payload.id).all().flatMap { addresses in
            guard addresses.count > 0, let address = addresses.first else { return request.eventLoop.makeFailedFuture(Abort(.badRequest, reason: "No address found!")) }
            
            address.street = content.street
            address.city = content.city
            address.zip = content.zip
            
            return address.save(on: request.db).map { _ in
                return AddressResponse(address)
            }
        }
    }
    
    func delete(_ request: Request) throws -> EventLoopFuture<HTTPStatus> {
        let id = ObjectId(request.parameters.get("id") ?? "") ?? ObjectId()
        
        return Address.query(on: request.db).filter(\.$id == id).filter(\.$userId == request.payload.id).all().flatMap { addresses in
            guard addresses.count > 0, let address = addresses.first else { return request.eventLoop.makeFailedFuture(Abort(.badRequest, reason: "No address found!")) }
            
            return address.delete(on: request.db).transform(to: .ok)
        }
    }
}
