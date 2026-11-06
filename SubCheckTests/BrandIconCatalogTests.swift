import UIKit
import XCTest
@testable import SubCheck

final class BrandIconCatalogTests: XCTestCase {

    func testIdsAreUnique() {
        let ids = BrandIconCatalog.all.map(\.id)
        XCTAssertEqual(ids.count, Set(ids).count, "ids repetidos quebram o índice do catálogo")
    }

    func testEveryLogoHasItsAssetInTheBundle() {
        for brand in BrandIconCatalog.all {
            guard let asset = brand.asset else { continue }
            XCTAssertNotNil(UIImage(named: asset), "falta o asset \(asset) de \(brand.name)")
        }
    }

    func testCatalogGrewWithTheRequestedBrands() {
        XCTAssertGreaterThan(BrandIconCatalog.all.count, 200)
        for id in ["appleone", "appledeveloper", "dazzcam", "capcut", "openai", "grok", "mistral", "lovable"] {
            XCTAssertNotNil(BrandIconCatalog.icon(id: id), id)
        }
    }

    func testDetectionFromNames() {
        func id(_ name: String) -> String? { BrandIconCatalog.match(name: name)?.id }
        XCTAssertEqual(id("Apple One"), "appleone")
        XCTAssertEqual(id("Apple Developer Program"), "appledeveloper")
        XCTAssertEqual(id("Dazz Cam"), "dazzcam")
        XCTAssertEqual(id("Smart Fit"), "smartfit")
        XCTAssertEqual(id("Microsoft Teams"), "teams")
        XCTAssertEqual(id("OneDrive"), "onedrive")
        XCTAssertEqual(id("Apple Arcade"), "applearcade")
        // As marcas que já existiam continuam ganhando.
        XCTAssertEqual(id("Apple Music"), "applemusic")
        XCTAssertEqual(id("Netflix"), "netflix")
        XCTAssertEqual(id("Cursor"), "cursor")
        XCTAssertEqual(id("Trae"), "trae")
        XCTAssertEqual(id("Claude Pro"), "claude")
    }

    func testTileBrandsKeepTheirColorWithoutALogo() {
        let dazz = BrandIconCatalog.icon(id: "dazzcam")
        XCTAssertNil(dazz?.asset)
        XCTAssertNotNil(dazz?.hex)
        XCTAssertFalse(dazz?.symbol.isEmpty ?? true)
    }
}
