//
//  PhotoDetailViewModel.swift
//  Pixxy
//
//  Created by Ganuke Perera on 1/5/23.
//

import Foundation
import Combine

class PhotoDetailViewModel: ObservableObject {
    
    @Published private(set) var imageData: Data?
    private var cancellables = Set<AnyCancellable>()
    let photoURL: String
    let photoService: ResourceLoader
    
    init(photoURL: String, photoService: ResourceLoader = PhotoService()){
        self.photoURL = photoURL
        self.photoService = photoService
    }
    
    func fetchPhotoData() {
        photoService.fetchData(from: photoURL)
            .sink { completion in
                //TODO: Error handling
                switch completion {
                case .failure(let error):
                    break
                case .finished:
                    break
                }
            } receiveValue: {[weak self] data in
                self?.imageData = data
            }
            .store(in: &cancellables)

    }
}
