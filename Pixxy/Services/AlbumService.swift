//
//  AlbumService.swift
//  Pixxy
//
//  Created by Ganuke Perera on 1/2/23.
//

import Foundation
import Combine

enum NetworkError: Error{
    case unsupportedRequest
    case invalidResponse
    case decodingError
    case unknown
}

extension NetworkError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .unsupportedRequest:
            return NSLocalizedString("Network.InvalidRequest", comment: "Request Not Supporte")
        case .invalidResponse:
            return NSLocalizedString("Network.InvalidResponse", comment: "Invalid response")
        case .decodingError:
            return NSLocalizedString("Network.DecodingError", comment: "JSON response processing error")
        case .unknown:
            return NSLocalizedString("Network.UnknownError", comment: "Unknown error")
        }
    }
}

protocol DataFetchable {
    func fetch<T: Codable>(endpoint: Endpoint, type: T.Type) -> Future<T, Error>
}

class AlbumService: DataFetchable {
    
    private var cancellable = Set<AnyCancellable>()
    
    func fetch<T: Codable>(endpoint: Endpoint, type: T.Type) -> Future<T, Error> {
        
        return Future<T, Error> { [weak self] promise in
            
            guard let self = self else {
                return promise(.failure(NetworkError.unknown))
            }
            guard let url = endpoint.url() else {
                return promise(.failure(NetworkError.unsupportedRequest))
            }
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
                        default:
                            promise(.failure(error))
                        }
                    }
                }, receiveValue: {
                    promise(.success($0))
                })
                .store(in: &self.cancellable)
        }
    }
}
