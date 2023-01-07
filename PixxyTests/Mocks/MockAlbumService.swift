//
//  MockAlbumService.swift
//  PixxyTests
//
//  Created by Ganuke Perera on 1/6/23.
//

import Foundation
import Combine

class MockAlbumService: DataFetchable {
    private let servicesToBeFailed: [String]!
    
    init(servicesToBeFailed: [String] = []){
        self.servicesToBeFailed = servicesToBeFailed
    }
    
    func fetch<T>(endpoint: Endpoint, type: T.Type) -> Future<T, Error> where T : Decodable, T : Encodable {
        return Future<T, Error> { [weak self] promise in
            let fileName: String?
            if endpoint.path == "/albums" {
                fileName = "Albums"
                
            }else if endpoint.path == "/users" {
                fileName = "Users"
                
            }else if endpoint.path == "/photos" {
                fileName = "Photos"
            }else{
                promise(.failure(NetworkError.unsupportedRequest))
                return
            }
            //MOCK FAIURES
            if self?.servicesToBeFailed.contains(fileName!) ?? false {
                promise(.failure(NetworkError.unsupportedRequest))
                return
            }
            let url = Bundle.main.url(forResource: fileName, withExtension: "json")
            guard let url = url,
                  let data = try? Data(contentsOf: url),
                  let mockyJSON = try? JSONDecoder().decode(T.self, from: data) else {
                      promise(.failure(NetworkError.decodingError))
                      return
                  }
            promise(.success(mockyJSON))
        }
    }
}
