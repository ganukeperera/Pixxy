//
//  AlbumService.swift
//  Pixxy
//
//  Created by Ganuke Perera on 1/2/23.
//

import Foundation
import Combine

enum NetworkError: Error{
    case badRequest
    case invalidResponse
    case decodingError
    case connectionError
    case unknown
}

protocol DataFetchable {
    func fetchData<T: Codable>(endpoint: Endpoint, type: T.Type) -> Future<T, Error>
}

class AlbumService: DataFetchable {
    private var cancellables = Set<AnyCancellable>()
    func fetchData<T: Codable>(endpoint: Endpoint, type: T.Type) -> Future<T, Error> {
        return Future<T, Error> { [weak self] promise in
            guard let self = self else {
                return promise(.failure(NetworkError.unknown))
            }
            var components = URLComponents()
            components.scheme = endpoint.scheme
            components.host = endpoint.baseURL
            components.path = endpoint.path
            components.queryItems = endpoint.components
            
            guard let url = components.url else {
                return
            }
            
            print("URL is \(url.absoluteString)")
            URLSession.shared.dataTaskPublisher(for: url)
                .tryMap { (data, response) -> Data in
                    guard let httpResponse = response as? HTTPURLResponse, 200...299 ~= httpResponse.statusCode else {
                        throw NetworkError.invalidResponse
                    }
                    return data
                }
                .decode(type: T.self, decoder: JSONDecoder())
                .receive(on: RunLoop.main)
                .sink(receiveCompletion: { (completion) in
                    if case let .failure(error) = completion {
                        switch error {
                        case let decodingError as DecodingError:
                            promise(.failure(decodingError))
                        case let apiError as NetworkError:
                            promise(.failure(apiError))
                        default:
                            promise(.failure(NetworkError.unknown))
                        }
                    }
                }, receiveValue: {
                    promise(.success($0))
                })
                .store(in: &self.cancellables)
        }
    }
}
