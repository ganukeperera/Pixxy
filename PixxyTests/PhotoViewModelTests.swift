//
//  PhotoViewModelTests.swift
//  Pixxy
//
//  Created by Ganuke Perera on 1/8/23.
//

import XCTest
import Combine

class PhotoViewModelTests: XCTestCase {
    
    private var cancellables: Set<AnyCancellable>!
    private var imagData: Data?
    private var downloadFailed = false
    
    override func setUp() {
        
        cancellables = []
        self.imagData = nil
        self.downloadFailed = false
    }
    
    func test_image_title_and_original_url_properly_set_when_initializing() {
        
        let imageTitle = "accusamus beatae ad facilis cum similique qui sunt"
        let originalURL = "https://via.placeholder.com/600/92c952"
        let photoService = MockPhotoService(photoType: .thumbinailImage)
        let photoViewModel = PhotoViewModel(title: imageTitle, thumbnailUrl: originalURL, url: originalURL, photoService: photoService)
        XCTAssertEqual(imageTitle, photoViewModel.title)
        XCTAssertEqual(originalURL, photoViewModel.url)
    }
    
    func test_original_image_download_success() {
        let photoService = MockPhotoService(photoType: .thumbinailImage)
        let photoViewModel = PhotoViewModel(title: "Dummy Title", thumbnailUrl: "DummyURL", url: "Dummy URL",photoService: photoService)
        let expectation = expectation(description: "PhotoDownload")
        
        photoViewModel.$imageData
            .dropFirst()
            .collect(1)
            .first()
            .sink(receiveCompletion: { completion in
                expectation.fulfill()
            }, receiveValue: { [weak self] imgData in
                self?.imagData = imgData.first ?? nil
            })
            .store(in: &cancellables)
        
        photoViewModel.fetchPhotoData()
        waitForExpectations(timeout: 10)
        XCTAssertNotNil(self.imagData)
        XCTAssertNotNil(UIImage(data: self.imagData!))
    }
    
    func test_should_emit_error_when_image_download_get_failed() {
        let photoService = MockPhotoService(photoType: .thumbinailImage, shouldFail: true)
        let photoViewModel = PhotoViewModel(title: "Dummy Title", thumbnailUrl: "DummyURL", url: "Dummy URL",photoService: photoService)
        let expectation = expectation(description: "PhotoDownload")
        photoViewModel.$imageDownloadFailed
            .dropFirst()
            .collect(1)
            .first()
            .sink(receiveCompletion: { completion in
                expectation.fulfill()
            }, receiveValue: { [weak self] downloadFailed in
                self?.downloadFailed = downloadFailed.first ?? false
            })
            .store(in: &cancellables)
        
        photoViewModel.fetchPhotoData()
        waitForExpectations(timeout: 10)
        XCTAssertTrue(self.downloadFailed)
    }
}
