//
//  MockPhotoService.swift
//  PixxyTests
//
//  Created by Ganuke Perera on 1/8/23.
//

import Foundation
import Combine

enum PhotoType {
    case thumbinailImage
    case originalImage
}

class MockPhotoService: ResourceLoader {
    
    let photoType: PhotoType
    let shouldFail: Bool
    
    init(photoType: PhotoType, shouldFail: Bool = false) {
        self.photoType = photoType
        self.shouldFail = shouldFail
    }
    
    func fetchData(from urlString: String) -> Future<Data,Error> {
        
        return Future<Data, Error> { [weak self] promise in
            guard let self = self else {
                return promise(.failure(NetworkError.unknown))
            }
            if self.shouldFail {
                return promise(.failure(NetworkError.invalidResponse))
            }
            let url: URL?
            switch self.photoType {
            case .thumbinailImage:
                url = Bundle.main.url(forResource: "150x150", withExtension: "png")
                
            case .originalImage:
                url = Bundle.main.url(forResource: "600x600", withExtension: "png")
            }
            
            guard let url = url,
                  let data = try? Data(contentsOf: url) else {
                      promise(.failure(NetworkError.decodingError))
                      return
                  }
            promise(.success(data))
        }
    }
}
