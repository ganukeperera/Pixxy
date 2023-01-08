//
//  PhotoCollectionViewModelTests.swift
//  PixxyTests
//
//  Created by Ganuke Perera on 1/8/23.
//

import XCTest
import Combine

class PhotoCollectionViewModelTests: XCTestCase {
    
    private var cancellables: Set<AnyCancellable>!
    private var loadingDataDone = false
    private var loadingData = true
    private var showErrorMessage = false
    
    override func setUp() {
        cancellables = []
    }
    
    func test_photo_api_return_photos_when_success() {
        
        let photoCollectionViewModel = PhotoCollectionViewModel(albumID: 1, albumTitle: "accusamus beatae ad facilis cum similique qui sunt", photosService: MockAlbumService())
        let expection = expectation(description: "fetchPhotos")
        photoCollectionViewModel.$reloadPhotoCollection
            .dropFirst()
            .collect(1)
            .first()
            .sink(receiveCompletion: { completion in
                expection.fulfill()
            }, receiveValue: { [weak self] loading in
                self?.loadingDataDone = loading.first ?? false
            })
            .store(in: &cancellables)
        photoCollectionViewModel.fetchPhotos()
        waitForExpectations(timeout: 10)
        XCTAssertTrue(self.loadingDataDone)
        XCTAssertEqual(50, photoCollectionViewModel.numberOfPhotos)
    }
    
    func test_emit_photo_loading_done_when_phtoto_api_success() {
        
        let photoCollectionViewModel = PhotoCollectionViewModel(albumID: 1, albumTitle: "accusamus beatae ad facilis cum similique qui sunt", photosService: MockAlbumService())
        let expection = expectation(description: "fetchPhotos")
        photoCollectionViewModel.$isPhotosLoading
            .dropFirst(2)
            .collect(1)
            .first()
            .sink(receiveCompletion: { completion in
                expection.fulfill()
            }, receiveValue: { [weak self] loading in
                self?.loadingData = loading.first ?? true
            })
            .store(in: &cancellables)
        photoCollectionViewModel.fetchPhotos()
        waitForExpectations(timeout: 10)
        XCTAssertFalse(self.loadingData)
    }
    
    func test_error_generate_when_photo_api_failed() {
        let failableServices = ["Photos"]
        let photoCollectionViewModel = PhotoCollectionViewModel(albumID: 1, albumTitle: "accusamus beatae ad facilis cum similique qui sunt", photosService: MockAlbumService(servicesToBeFailed: failableServices))
        let expection = expectation(description: "fetchPhotos")
        photoCollectionViewModel.$showErroMessage
            .dropFirst()
            .collect(1)
            .first()
            .sink(receiveCompletion: { completion in
                expection.fulfill()
            }, receiveValue: { [weak self] showMessage in
                self?.showErrorMessage = showMessage.first ?? false
            })
            .store(in: &cancellables)
        photoCollectionViewModel.fetchPhotos()
        waitForExpectations(timeout: 10)
        XCTAssertTrue(self.showErrorMessage)
        XCTAssertNotNil(photoCollectionViewModel.errorMessage)
    }
}
