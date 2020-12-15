import Fluent
import Vapor

func routes(_ app: Application) throws {
    app.get([.anything, "name", "health"]) { req in
        return "Healthy!"
    }
    
    // additional routes
    
}
