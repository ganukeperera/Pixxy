//
//  PhotoDetailViewModel.swift
//  Pixxy
//
//  Created by Ganuke Perera on 1/5/23.
//

import Foundation
import Combine

class PhotoDetailViewModel: ObservableObject {
    
    //MARK: - Properties
    @Published private(set) var imageData: Data?
    @Published private(set) var imageDownloadFailed = false
    private var cancellables = Set<AnyCancellable>()
    private let photoURL: String
    private let photoService: ResourceLoader
    let photoTitle: String
    
    //MARK: - Lifetiem
    init(photoURL: String, photoTitle: String, photoService: ResourceLoader = PhotoService()){
        self.photoURL = photoURL
        self.photoService = photoService
        self.photoTitle = photoTitle
    }
    
    //MARK: - APIs provided for the View
    func fetchPhotoData() {
        photoService.fetchData(from: photoURL)
            .sink {[weak self] completion in
                if case let .failure(error) = completion {
                    print("Downloading failed for the image url \(self?.photoURL ?? ""). Error: \(error.localizedDescription)")
                    self?.imageDownloadFailed = true
                }
            } receiveValue: {[weak self] data in
                self?.imageData = data
            }
            .store(in: &cancellables)
    }
}
