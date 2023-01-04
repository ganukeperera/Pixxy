//
//  AlbumEndpoint.swift
//  Pixxy
//
//  Created by Ganuke Perera on 1/2/23.
//

import Foundation

protocol Endpoint {
    
    var scheme: String {get}
    var baseURL: String {get}
    var path: String {get}
    var components: [URLQueryItem] {get}
    var method: String {get}
}

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
