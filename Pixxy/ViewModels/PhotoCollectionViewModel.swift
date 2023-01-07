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
    @Published private(set) var showErroMessage = false
    private var cancellables = Set<AnyCancellable>()
    private var photoViewModels = [PhotoViewModel](){
        didSet {
            reloadPhotoCollection = true
        }
    }
    private let photosService: DataFetchable
    private let albumID: Int
    let albumTitle: String
    private var errorType: ErrorType?
    private var errorOccurred = false
    private(set) var errorMessage: String? {
        didSet{
            showErroMessage = true
        }
    }
    
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
    
    var isRetryAllowed: Bool{
        
        switch errorType {
        case .APIError:
            return true
        default:
            return false
        }
    }
    
    func retryAction() {
        
        switch errorType {
        case .APIError:
            fetchPhotos()
        default:
            break
        }
    }
    
    func fetchPhotos(){
        isPhotosLoading = true
        photosService.fetch(endpoint: AlbumEndpoint.fetchPhotos(albumId: albumID), type: [Photo].self)
            .sink { [weak self] completion in
                if case let .failure(error) = completion {
                    //Application will not be able to if Album endpoint throws an error. Appliation will show a error message
                    switch error {
                    case let networkError as NetworkError:
                        self?.errorMessage = networkError.localizedDescription
                    default:
                        self?.errorMessage = NSLocalizedString("PhotoCVC.Error.PhotoAPI", comment: "Photo Collection API erro")
                    }
                    self?.errorType = .APIError
                }
        } receiveValue: { [weak self] photoList in
            self?.isPhotosLoading = false
            self?.processPhotos(photoList: photoList)
        }.store(in: &cancellables)
    }
    
    func processPhotos(photoList: [Photo]) {
        DispatchQueue.global(qos: .userInitiated).async {
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
    @Published private(set) var imageDownloadFailed = false
    
    init(title: String, thumbnailUrl: String, url: String, photoService: ResourceLoader = PhotoService()) {
        self.title = title
        self.thumbnailUrl = thumbnailUrl
        self.url = url
        self.photoService = photoService
    }
    
    func fetchPhotoData() {
        photoService.fetchData(from: thumbnailUrl)
            .sink { [weak self] completion in
                if case let .failure(error) = completion {
                    print("Downloading failed for the thumbinail url \(self?.thumbnailUrl ?? ""). Error: \(error.localizedDescription)")
                    self?.imageDownloadFailed = true
                }
            } receiveValue: {[weak self] data in
                self?.imageData = data
            }
            .store(in: &cancellables)

    }
}
