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
    private let photoURL: String
    private let photoService: ResourceLoader
    let photoTitle: String
    
    init(photoURL: String, photoTitle: String, photoService: ResourceLoader = PhotoService()){
        self.photoURL = photoURL
        self.photoService = photoService
        self.photoTitle = photoTitle
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
