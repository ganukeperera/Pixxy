//
//  PixxyTests.swift
//  PixxyTests
//
//  Created by Ganuke Perera on 1/1/23.
//

import XCTest
import Combine

class AlbumListViewModelTests: XCTestCase {
    
    private var cancellables: Set<AnyCancellable>!
    private var shouldReloadData: Bool = false
    private var isLoadingDataDone: Bool = true
    private var showErrorMessage: Bool = false
    
    override func setUp() {
        
        super.setUp()
        cancellables = []
        shouldReloadData = false
        isLoadingDataDone = true
        showErrorMessage = false
    }
    
    func test_fetch_albums_and_users_success() {
        
        let albumListViewModel = AlbumListViewModel(service: MockAlbumService())
        let expectation = self.expectation(description: "FetchAlbums")
        
        albumListViewModel.$reloadAlbumList
            .dropFirst()
            .collect(1)
            .first()
            .sink(receiveCompletion: { completion in
                expectation.fulfill()
            }, receiveValue: { [weak self] value in
                self?.shouldReloadData = value.first ?? false
            })
            .store(in: &cancellables)
        
        albumListViewModel.fetchAlbums()
        waitForExpectations(timeout: 10)
        XCTAssertTrue(self.shouldReloadData)
        XCTAssertEqual(10, albumListViewModel.numberOfSections)
        XCTAssertEqual(10, albumListViewModel.numberOfRowsInSection(section: 0))
        XCTAssertEqual(10, albumListViewModel.numberOfRowsInSection(section: 9))
    }
    
    func test_emit_loading_done_when_albums_and_users_requests_completed() {
        
        let albumListViewModel = AlbumListViewModel(service: MockAlbumService())
        let expectation = self.expectation(description: "FetchAlbums")
        
        albumListViewModel.$isAlbumsLoading
            .dropFirst(2)
            .collect(1)
            .first()
            .sink(receiveCompletion: { completion in
                expectation.fulfill()
            }, receiveValue: { [weak self] value in
                self?.isLoadingDataDone = value.first ?? true
            })
            .store(in: &cancellables)
        
        albumListViewModel.fetchAlbums()
        
        waitForExpectations(timeout: 10)
        XCTAssertFalse(self.isLoadingDataDone)
        XCTAssertEqual(10, albumListViewModel.numberOfSections)
    }
    
    //when user api get failed all albums need to be loaded for a single section in the table view
    func test_user_api_failed_albums_will_loaded_into_single_section() {
        
        let needToFailAPIs = ["Users"]
        let mockService = MockAlbumService(servicesToBeFailed: needToFailAPIs)
        let albumListViewModel = AlbumListViewModel(service: mockService)
        let expectation = self.expectation(description: "FetchAlbums")
        
        albumListViewModel.$reloadAlbumList
            .dropFirst()
            .collect(1)
            .first()
            .sink(receiveCompletion: { completion in
                expectation.fulfill()
            }, receiveValue: { [weak self] value in
                self?.shouldReloadData = value.first ?? false
            })
            .store(in: &cancellables)
        
        albumListViewModel.fetchAlbums()
        waitForExpectations(timeout: 10)
        XCTAssertTrue(self.shouldReloadData)
        XCTAssertEqual(1, albumListViewModel.numberOfSections)
        XCTAssertEqual(100, albumListViewModel.numberOfRowsInSection(section: 0))
    }
    
    func test_error_generated_when_both_albums_and_users_requests_get_failed() {
        
        let needToFailAPIs = ["Albums","Users"]
        let mockService = MockAlbumService(servicesToBeFailed: needToFailAPIs)
        let albumListViewModel = AlbumListViewModel(service: mockService)
        let expectation = self.expectation(description: "FetchAlbums")
        
        albumListViewModel.$showErroMessage
            .dropFirst()
            .collect(1)
            .first()
            .sink(receiveCompletion: { completion in
                expectation.fulfill()
            }, receiveValue: { [weak self] showMessage in
                self?.showErrorMessage = showMessage.first ?? false
            })
            .store(in: &cancellables)
        
        albumListViewModel.fetchAlbums()
        waitForExpectations(timeout: 10)
        XCTAssertTrue(self.showErrorMessage)
        XCTAssertNotNil(albumListViewModel.errorMessage)
        XCTAssertEqual(true, albumListViewModel.isRetryAllowed)
    }
}
