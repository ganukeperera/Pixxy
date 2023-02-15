//
//  PixxyUITest.swift
//  PixxyUITest
//
//  Created by Ganuke Perera on 1/8/23.
//

import XCTest

class PixxyUITest: XCTestCase {

    private var app: XCUIApplication!
    
    override func setUp() {
        app = XCUIApplication()
        continueAfterFailure = false
    }

    func test_app_initiated_with_album_list_view_controller() throws {
        app.launchArguments = ["-MockService"]
        app.launch()
        let testBundle = Bundle(for: type(of: self ))
        let homeTitle = NSLocalizedString("AlbumListVC.NavCTRL.Title", bundle: testBundle, value: "Album", comment: "")
        let homeNavBarTitle = app.navigationBars.staticTexts[homeTitle]
        XCTAssertTrue(homeNavBarTitle.waitForExistence(timeout: 2.0))
    }
    
    func test_table_view_contains_all_albums() {
        app.launchArguments = ["-MockService"]
        app.launch()
        XCTAssertEqual(100, app.tables.cells.count)
    }
    
    func test_user_should_navigate_to_photo_collection_view_when_first_album_selected() {
        app.launchArguments = ["-MockService"]
        app.launch()
        let testBundle = Bundle(for: type(of: self ))
        let homeTitle = NSLocalizedString("AlbumListVC.NavCTRL.Title", bundle: testBundle, value: "Album", comment: "")
        let homeNavBarTitle = app.navigationBars.staticTexts[homeTitle]
        XCTAssertTrue(homeNavBarTitle.waitForExistence(timeout: 2.0))
        let firstAlbumCell = app.cells["Cell_0_0"]
        firstAlbumCell.tap()
        XCTAssertFalse( app.navigationBars.staticTexts[homeTitle].exists)
    }
    
    func test_user_should_navigate_to_photo_detail_view_when_select_thumbinail_image() {
        app.launchArguments = ["-MockService"]
        app.launch()
        let firstTableCell = app.tables.cells["Cell_0_0"]
        firstTableCell.tap()
        XCTAssertTrue(app.collectionViews.element.waitForExistence(timeout: 2.0))
        let firstCollectoinViewCell = app.collectionViews.cells["PhotoCell_0_0"]
        XCTAssertTrue(firstCollectoinViewCell.exists)
        firstCollectoinViewCell.tap()
        let originalImage = app.images.element
        XCTAssertTrue(originalImage.exists)
        XCTAssertEqual(app.images.count,1)
    }
    
    func test_user_should_able_to_select_first_album_even_if_users_endpoint_failed() {
        app.launchArguments = ["-MockService","-FailUsers"]
        app.launch()
        let cellTitle = "Quidem Molestiae Enim"
        let firstAlbumCell = app.tables.staticTexts[cellTitle]
        firstAlbumCell.tap()
        let homeNavBarTitle = app.staticTexts[cellTitle]
        XCTAssertTrue(homeNavBarTitle.waitForExistence(timeout: 5.0))
        
    }
    
    func test_user_should_see_a_alert_with_retry_option_when_album_endpoint_fails() {
        app = XCUIApplication()
        continueAfterFailure = false
        app.launchArguments = ["-MockService","-FailAlbums"]
        app.launch()
        XCUIApplication().alerts["Alert"].scrollViews.otherElements.buttons["Retry"].tap()
                        
    }
}
