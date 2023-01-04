//
//  PhotoCollectionViewModel.swift
//  Pixxy
//
//  Created by Ganuke Perera on 1/3/23.
//

import Foundation
import Combine

class PhotoCollectionViewModel {
    
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
    
    init(photosService: DataFetchable = AlbumService(),albumID: Int) {
        self.photosService = photosService
        self.albumID = albumID
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
        photosService.fetchData(endpoint: AlbumEndpoint.fetchPhotos(albumId: albumID), type: [Photo].self).sink { completion in
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

struct PhotoViewModel {
    let title: String
    let thumbnailUrl: String
    let url: String
}
