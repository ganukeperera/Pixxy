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

extension NetworkError: LocalizedError {
    var errorDescription: String? {
//        switch self {
//        case .invalidURL:
//            return NSLocalizedString("Invalid URL", comment: "Invalid URL")
//        case .responseError:
//            return NSLocalizedString("Unexpected status code", comment: "Invalid response")
//        case .unknown:
//            return NSLocalizedString("Unknown error", comment: "Unknown error")
//        }
        ""
    }
}

protocol DataFetchable {
    func fetch<T: Codable>(endpoint: Endpoint, type: T.Type) -> Future<T, Error>
}

class AlbumService: DataFetchable {
    private var cancellable = Set<AnyCancellable>()
    //TODO: hererError or Network error
    func fetch<T: Codable>(endpoint: Endpoint, type: T.Type) -> Future<T, Error> {
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
                .store(in: &self.cancellable)
        }
    }
}
