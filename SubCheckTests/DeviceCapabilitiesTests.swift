import XCTest
@testable import SubCheck

final class DeviceCapabilitiesTests: XCTestCase {

    func testSafeAreaDecidesWhenAvailable() {
        // iPhone 15 (ilha): 59 pt · iPhone 13 (entalhe): 47 pt · iPhone 16 Pro: 62 pt
        XCTAssertTrue(DeviceCapabilities.hasIsland(safeAreaTop: 59, modelIdentifier: "iPhone15,4", isPhone: true))
        XCTAssertTrue(DeviceCapabilities.hasIsland(safeAreaTop: 62, modelIdentifier: "iPhone17,1", isPhone: true))
        XCTAssertFalse(DeviceCapabilities.hasIsland(safeAreaTop: 47, modelIdentifier: "iPhone14,5", isPhone: true))
        XCTAssertFalse(DeviceCapabilities.hasIsland(safeAreaTop: 50, modelIdentifier: "iPhone14,7", isPhone: true))
        XCTAssertFalse(DeviceCapabilities.hasIsland(safeAreaTop: 20, modelIdentifier: "iPhone12,8", isPhone: true)) // SE
    }

    func testModelFallbackWhenInsetIsZero() {
        XCTAssertTrue(DeviceCapabilities.hasIsland(safeAreaTop: 0, modelIdentifier: "iPhone15,2", isPhone: true))  // 14 Pro
        XCTAssertFalse(DeviceCapabilities.hasIsland(safeAreaTop: 0, modelIdentifier: "iPhone15,1", isPhone: true)) // inexistente/entalhe
        XCTAssertFalse(DeviceCapabilities.hasIsland(safeAreaTop: 0, modelIdentifier: "iPhone14,7", isPhone: true)) // 14 (entalhe)
        XCTAssertTrue(DeviceCapabilities.hasIsland(safeAreaTop: 0, modelIdentifier: "iPhone16,1", isPhone: true))  // 15 Pro
        XCTAssertFalse(DeviceCapabilities.hasIsland(safeAreaTop: 0, modelIdentifier: "iPhone17,5", isPhone: true)) // 16e
    }

    func testIPadAndUnknownNeverHaveTheIsland() {
        XCTAssertFalse(DeviceCapabilities.hasIsland(safeAreaTop: 24, modelIdentifier: "iPad16,3", isPhone: false))
        XCTAssertFalse(DeviceCapabilities.modelHasIsland("x86_64"))
        XCTAssertFalse(DeviceCapabilities.modelHasIsland("iPhone"))
    }
}
