//
//  AlbumEndpoint.swift
//  Pixxy
//
//  Created by Ganuke Perera on 1/2/23.
//

import Foundation

//All album service endpoints will be configured by conforming to this protocol
protocol Endpoint {
    
    var scheme: String {get}
    var baseURL: String {get}
    var path: String {get}
    var components: [URLQueryItem] {get}
    var method: String {get}
}

//This extension provide a default implementation to get a URL object by processing all properties of Endpoint
extension Endpoint {
    
    func url() -> URL? {
        var urlComponents = URLComponents()
        urlComponents.scheme = scheme
        urlComponents.host = baseURL
        urlComponents.path = path
        urlComponents.queryItems = components
        return urlComponents.url
    }
}

//Configure all endpoints by conforming to Endpoint  protocol
enum AlbumEndpoint: Endpoint {
    
    case fetchAllAlbums
    case fetchAllUsers
    case fetchPhotos(albumId: Int)
    
    var scheme: String{
        return "https"
    }
    
    var baseURL: String{
        switch self {
        default:
            return "jsonplaceholder.typicode.com"
        }
    }
    
    var path: String{
        switch self {
        case .fetchAllAlbums:
            return "/albums"
        case .fetchAllUsers:
            return "/users"
        case .fetchPhotos:
            return "/photos"
        }
    }
    
    var components: [URLQueryItem] {
        switch self {
        case .fetchPhotos(let albumId):
            return [URLQueryItem(name: "albumId", value: String(albumId))]
        default:
            return []
        }
    }
    
    var method: String {
        switch self {
        default:
            return "GET"
        }
    }
}

