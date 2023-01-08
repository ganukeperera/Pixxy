//
//  PhotoDetailViewModelTests.swift
//  PixxyTests
//
//  Created by Ganuke Perera on 1/8/23.
//

import XCTest
import Combine

class PhotoDetailViewModelTests: XCTestCase {
    
    private var cancellables: Set<AnyCancellable>!
    private var imagData: Data?
    private var downloadFailed = false
    
    override func setUp() {
        cancellables = []
        self.imagData = nil
        self.downloadFailed = false
    }
    
    func test_original_image_download_success() {
        
        let photoService = MockPhotoService(photoType: .originalImage)
        let photoDetailViewModel = PhotoDetailViewModel(photoURL: "dummy URL", photoTitle: "Mock Original Image", photoService: photoService)
        let expectation = expectation(description: "PhotoDownload")
        
        photoDetailViewModel.$imageData
            .dropFirst()
            .collect(1)
            .first()
            .sink(receiveCompletion: { completion in
                expectation.fulfill()
            }, receiveValue: { [weak self] imgData in
                self?.imagData = imgData.first ?? nil
            })
            .store(in: &cancellables)
        
        photoDetailViewModel.fetchPhotoData()
        waitForExpectations(timeout: 10)
        XCTAssertNotNil(self.imagData)
        XCTAssertNotNil(UIImage(data: self.imagData!))
    }
    
    func test_should_emit_error_when_image_download_get_failed() {
        
        let photoService = MockPhotoService(photoType: .originalImage,shouldFail: true)
        let photoDetailViewModel = PhotoDetailViewModel(photoURL: "dummy URL", photoTitle: "Mock Original Image", photoService: photoService)
        let expectation = expectation(description: "PhotoDownload")
        
        photoDetailViewModel.$imageDownloadFailed
            .dropFirst()
            .collect(1)
            .first()
            .sink(receiveCompletion: { completion in
                expectation.fulfill()
            }, receiveValue: { [weak self] downloadFailed in
                self?.downloadFailed = downloadFailed.first ?? false
            })
            .store(in: &cancellables)
        
        photoDetailViewModel.fetchPhotoData()
        waitForExpectations(timeout: 10)
        XCTAssertTrue(self.downloadFailed)
    }
}
