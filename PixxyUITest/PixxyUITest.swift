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
        let homeNavBarTitle = app.staticTexts[homeTitle]
        XCTAssertTrue(homeNavBarTitle.waitForExistence(timeout: 2.0))
    }
    
    
    func test_user_should_navigate_to_photo_collection_view_when_first_album_selected() {
        app.launchArguments = ["-MockService"]
        app.launch()
        let cellTitle = "Quidem Molestiae Enim"
        let firstAlbumCell = app.tables.staticTexts[cellTitle]
//        let firstAlbumCell = app.cells["Cell_0_0"]
//        let cellTitle = firstAlbumCell.descendants(matching: .staticText).element.title
        firstAlbumCell.tap()
        let homeNavBarTitle = app.staticTexts[cellTitle]
        XCTAssertTrue(homeNavBarTitle.waitForExistence(timeout: 2.0))
    }
    
    func test_user_should_able_to_select_first_album_even_if_users_endpoint_failed() {
        app.launchArguments = ["-MockService","-FailUsers"]
        app.launch()
        let cellTitle = "Quidem Molestiae Enim"
        let firstAlbumCell = app.tables.staticTexts[cellTitle]
//        let firstAlbumCell = app.cells["Cell_0_0"]
//        let cellTitle = firstAlbumCell.descendants(matching: .staticText).element.title
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
