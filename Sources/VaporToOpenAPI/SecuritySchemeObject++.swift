import Foundation
import SwiftOpenAPI
import Vapor

public struct AuthSchemeObject: Equatable, Identifiable {

    public let id: String
    public let scheme: SecuritySchemeObject
    
    public init(id: String? = nil, scheme: SecuritySchemeObject) {
        self.id = id ?? scheme.autoName
        self.scheme = scheme
    }
}

public extension AuthSchemeObject {
    
    /// Basic authentication is a simple authentication scheme built into the HTTP protocol. The client sends HTTP requests with the Authorization header that contains the word Basic word followed by a space and a base64-encoded string username:password. For example, to authorize as demo / p@55w0rd the client would send
    static var basic: AuthSchemeObject {
        .basic()
    }
    
    /// Basic authentication is a simple authentication scheme built into the HTTP protocol. The client sends HTTP requests with the Authorization header that contains the word Basic word followed by a space and a base64-encoded string username:password. For example, to authorize as demo / p@55w0rd the client would send
    static func basic(
        id: String? = nil,
        description: String? = nil
    ) -> AuthSchemeObject {
        AuthSchemeObject(scheme: .basic(description: description))
    }
    
    /// An API key is a token that a client provides when making API calls
    static func apiKey(
        id: String? = nil,
        name: String = "X-API-Key",
        in location: SecuritySchemeObject.Location = .header,
        description: String? = nil
    ) -> AuthSchemeObject {
        AuthSchemeObject(id: id, scheme: .apiKey(name: name, in: location, description: description))
    }
    
    /// Bearer authentication (also called token authentication) is an HTTP authentication scheme that involves security tokens called bearer tokens. The name “Bearer authentication” can be understood as “give access to the bearer of this token.” The bearer token is a cryptic string, usually generated by the server in response to a login request. The client must send this token in the Authorization header when making requests to protected resources
    static func bearer(
        id: String? = nil,
        format: String? = nil,
        description: String? = nil
    ) -> AuthSchemeObject {
        AuthSchemeObject(id: id, scheme: .bearer(format: format, description: description))
    }
    
    /// OAuth 2.0 is an authorization protocol that gives an API client limited access to user data on a web server. GitHub, Google, and Facebook APIs notably use it. OAuth relies on authentication scenarios called flows, which allow the resource owner (user) to share the protected content from the resource server without sharing their credentials. For that purpose, an OAuth 2.0 server issues access tokens that the client applications can use to access protected resources on behalf of the resource owner. For more information about OAuth 2.0, see oauth.net and RFC 6749.
    static func oauth2(
        _ type: SecuritySchemeObject.OAuth2,
        id: String? = nil,
        refreshUrl: String? = nil,
        scopes: [String: String] = [:],
        description: String? = nil
    ) -> AuthSchemeObject {
        AuthSchemeObject(id: id, scheme: .oauth2(type, refreshUrl: refreshUrl, scopes: scopes, description: description))
    }
    
    /// OpenID Connect (OIDC) is an identity layer built on top of the OAuth 2.0 protocol and supported by some OAuth 2.0 providers, such as Google and Azure Active Directory. It defines a sign-in flow that enables a client application to authenticate a user, and to obtain information (or "claims") about that user, such as the user name, email, and so on. User identity information is encoded in a secure JSON Web Token (JWT), called ID token.
    static func openIDConnect(id: String? = nil, url: String, description: String? = nil) -> AuthSchemeObject {
        AuthSchemeObject(id: id, scheme: .openIDConnect(url: url, description: description))
    }
}

extension SecuritySchemeObject {
    
    var autoName: String {
        [
            type.rawValue,
            scheme?.rawValue,
            bearerFormat,
            `in`?.rawValue,
            (flows?.password).map { _ in "password" },
            (flows?.clientCredentials).map { _ in "clientCredentials" },
            (flows?.authorizationCode).map { _ in "authorizationCode" },
            (flows?.implicit).map { _ in "implicit" }
        ]
            .compactMap { $0 }
            .joined(separator: "_")
    }
    
    var allScopes: [String] {
        [
        	flows?.implicit?.scopes,
        	flows?.authorizationCode?.scopes,
        	flows?.clientCredentials?.scopes,
        	flows?.password?.scopes
        ].flatMap { ($0 ?? [:]).keys }
    }
}
    
extension Route {
    
    func setNew(
        auth: [AuthSchemeObject],
        scopes: [String]
    ) -> Route {
        let newAuth = (auths + auth).removeEquals
        return set(\.auths, to: newAuth)
            .openAPI(custom: \.security, securities(auth: newAuth, scopes: scopes, old: operationObject.security))
    }
    
}

func securities(
    auth: [AuthSchemeObject],
    scopes: [String] = [],
    old: [SecurityRequirementObject]? = nil
) -> [SecurityRequirementObject]? {
    auth.map { auth in
        let name = auth.id
        return SecurityRequirementObject(
            name,
            ((old?.first(where: { $0.name == name })?.values ?? []) + scopes).nilIfEmpty ?? auth.scheme.allScopes
        )
    }.nilIfEmpty
}
