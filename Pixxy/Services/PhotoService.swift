//
//  PhotoService.swift
//  Pixxy
//
//  Created by Ganuke Perera on 1/5/23.
//

import Foundation
import Combine

protocol ResourceLoader {
    func fetchData(from urlString: String) -> Future<Data,Error>
}

class PhotoService: ResourceLoader {
    private var cancellable: AnyCancellable?
    
    deinit {
        cancel()
    }
    
    func fetchData(from urlString: String) -> Future<Data,Error> {
        //
        return Future<Data, Error> { [weak self] promise in
            guard let self = self else {
                return promise(.failure(NetworkError.unknown))
            }
            
            guard let url = URL(string: urlString) else {
                return
            }
            let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: Constant.Network.requestTimeOut)
            //TODO: Error handeling
            self.cancellable = URLSession.shared.dataTaskPublisher(for: request)
                .tryMap { (data, response) -> Data in
                    guard let httpResponse = response as? HTTPURLResponse, 200...299 ~= httpResponse.statusCode else {
                        throw NetworkError.invalidResponse
                    }
                    return data
                }
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
            
        }
    }
    
    private func cancel() {
        cancellable?.cancel()
    }
    
}
