//
//  PhotoCollectionViewModel.swift
//  Pixxy
//
//  Created by Ganuke Perera on 1/3/23.
//

import Foundation
import Combine

class PhotoCollectionViewModel: ObservableObject {
    
    @Published private(set) var isPhotosLoading = false
    @Published private(set) var reloadPhotoCollection = false
    private var cancellables = Set<AnyCancellable>()
    private var photoViewModels = [PhotoViewModel](){
        didSet {
            reloadPhotoCollection = true
        }
    }
    private let photosService: DataFetchable
    private let albumID: Int
    let albumTitle: String
    
    init(albumID: Int, albumTitle: String, photosService: DataFetchable = AlbumService()) {
        self.photosService = photosService
        self.albumID = albumID
        self.albumTitle = albumTitle
    }
    
    var numberOfPhotos: Int {
        photoViewModels.count
    }
    
    func getPhotoViewModel(at index: Int) -> PhotoViewModel? {
        guard index < photoViewModels.count else {
            return nil
        }
        return photoViewModels[index]
    }
    
    func fetchPhotos(){
        isPhotosLoading = true
        photosService.fetch(endpoint: AlbumEndpoint.fetchPhotos(albumId: albumID), type: [Photo].self)
            .sink { completion in
            switch completion {
            case .failure(let error):
                break
            case .finished:
                break
            }
        } receiveValue: { [weak self] photoList in
            self?.isPhotosLoading = false
            self?.processPhotos(photoList: photoList)
        }.store(in: &cancellables)
    }
    
    func processPhotos(photoList: [Photo]) {
        //TODO: User initiated or user interactive
        //TODO: Weak self or self
        DispatchQueue.global(qos: .userInteractive).async {
            var viewModelList = [PhotoViewModel]()
            for photo in photoList {
                let photoViewModel = PhotoViewModel(title: photo.title, thumbnailUrl: photo.thumbnailUrl, url: photo.url)
                viewModelList.append(photoViewModel)
            }
            self.photoViewModels = viewModelList
        }
    }
}

class PhotoViewModel: ObservableObject {
    let title: String
    let url: String
    private let thumbnailUrl: String
    private let photoService: ResourceLoader
    private var cancellables = Set<AnyCancellable>()
    @Published private(set) var imageData: Data?
    
    init(title: String, thumbnailUrl: String, url: String, photoService: ResourceLoader = PhotoService()) {
        self.title = title
        self.thumbnailUrl = thumbnailUrl
        self.url = url
        self.photoService = photoService
    }
    
    func fetchPhotoData() {
        photoService.fetchData(from: thumbnailUrl)
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
