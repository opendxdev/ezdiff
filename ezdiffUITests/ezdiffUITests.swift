//
//  ezdiffUITests.swift
//  ezdiffUITests
//
//  Created by Deep Mandloi on 3/6/26.
//

import XCTest

final class ezdiffUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testAppLaunchesSuccessfully() throws {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.windows.count > 0, "App should have at least one window")
    }

    @MainActor
    func testDropZonesVisibleOnLaunch() throws {
        let app = XCUIApplication()
        app.launch()

        let leftDropZone = app.otherElements["leftDropZone"]
        let rightDropZone = app.otherElements["rightDropZone"]
        XCTAssertTrue(leftDropZone.waitForExistence(timeout: 5), "Left drop zone should be visible")
        XCTAssertTrue(rightDropZone.waitForExistence(timeout: 5), "Right drop zone should be visible")
    }
}
