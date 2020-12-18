import Fluent
import FluentMongoDriver
import Vapor
import JWT
import SendGrid

// configures your application
public func configure(_ app: Application) throws {
    // MARK: JWT
    print("configure 1")
    let jwksString = """
    { "keys": [ { "p": "-JxZekvQVJNlt-JoOx7Ns_aVJE1ElG3d2MISIfNvVqE7kwvt5DHa-rniHFTJJ1TCSWJEtw_qwbI1pgcqICoHxpCViChWW3R_LuTGXArXUQKoqZEpT3NpVlfGnbjgpqL5_rfUF92-3iTpB1RXANgsoeKpnz1az_kGvp2HkX9Jd9U", "kty": "RSA", "q": "noD4jFONY0fXUAUK_LZJ5Nl9uajvehe8TD0FG3WKjYoKfLvacjtMqlSCe8kvARGNXUnb1hpBUGwByGJHHDhBcsnT5xAgEutrbceSPCSiR6IAZeLHSbOpZ3ibinUVdJ1nFRStFUlXhfDaXkuPt5wVQcU_MzmmC0fopgoRJOnjAkc", "d": "bT3kKXuSLjRXbwjhFyDGdxXpkCAUX1vT1WehVn9fjjsRn_fD2TZYgkb_xoPEhdrr0w1GJiHja04IHN0uKymbNJAnVrBSKZn6X3VYJ1rvj6EJwZiGTs05MJgOmZNUMA4d-QVYaiUvdboh_8KgGWthEGICcLV_xoG5NDuXtp1SSQIFslyQ6sF3d1DFKJyIxkrtzhFf4H277Ju4es7sVsw-rxfsP0crY1afiDDhBHAqSPMoTZWx_ShnFfK-8TTzuZPsHGsbGvyCbpX9H700K_QFjgGxrv5KUn1ocNaQmLCtgLIjJtRBKBUaIsGIavCERxU502db0ijN_b2jyNh1G3UmiQ", "e": "AQAB", "use": "sig", "kid": "backend", "qi": "EffJgOWDtNLmz1iJftElX0wly_XutZRTVkF-oubs66z-p_QED5HgvBWk8LD-xHDA0sgv7_j6cAuQY9_pwAAwZTQHkBWTXl-DWKoeMYzVdMGPjxSnsOn0NEAi5_EF2L74ZoAXqV0l50YmnYvZP8R5E3A7fDuUQNALJf65zpJmf8M", "dp": "uJLbm4BN23zTOAJPgBUOg12-vIThNZGb8yGidLJXJuntYO6qX5DkEuGOjZok_Z5f4Duk6IRYthWo3urSy65ot3MAkWXhN2T2R8pxukQSN4LR1ZKAKQx2WDQysUZhA1ZcZE_2lwF6g1LD7z0emvHjsQynAiJ7GYy5BSvPSqZF1UE", "alg": "RS256", "dq": "bmOuNrT-FHX1S8KnW0dtgVfDyykP1_1t477frrcXDupj0WlXgxUvmLUQxztfZCQgSydkVuGkOWlveGqR0eKQGmzcCuHdJLAW-rbybrao2rDGDC970iWxRuHlmfFfRv9UyobC4L9amGsc-m0vo5Wt7Ed-c6Ojs9mZ-wGp3QaTVoM", "n": "me2-xfVD5Dq0V9MhqE7v6_1AZHKIEZHydKwjdTw1mLP13gDkAZNCjZ371hQVpqTP7soPqUzOkD9s_bkRtV_go4LyZ3ETK5Zo4e3_4fydUhBEQ9hCktXKCXwhAuwZ-dCqRPC2SsmDU6SnItmIABtyK3GuIBaiqt2gHmitGrHoWzivOA-G9REPBIlp3Ln4NyENr7BPj0DElmjcjJpNwAgjc4SbN1o6DNg5yrNaaDnQe9Q5PSummo_fOrL93UOURqGx30xEB9T-UsDGIN_n-S8RgeBCTw6QbW4ogwd5ZijSchWjPYcJw2plNQIRO7XRabQN5crz56twhvNPOXeC_y7mEw" } ]}
    """
//    guard let jwksString = Environment.get("JWKS_KEYPAIR") else {
//        fatalError("No value was found at the given public key environment 'JWKS_KEYPAIR'")
//    }
    let jwksString2 = Environment.get("JWKS_KEYPAIR")
    print("configure jwksString2:", jwksString2)
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
