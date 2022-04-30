//
//  AcceptanceTests.swift
//  AcceptanceTests
//
//  Created by Paul Zabelin on 4/29/22.
//

import XCTest
import EncryptCard

class AcceptanceTests: XCTestCase {
    func testPGEncrypt() throws {
        let card = PGKeyedCard(cardNumber: "4111111111111111", expirationDate: "10/25", cvv: "123")
        let encrypt = PGEncrypt()
        let key = try! String(contentsOf: URL(fileURLWithPath: "/tmp/key.txt"))
        encrypt.setKey(key)
        let encrypted = encrypt.encrypt(card, includeCVV: true)!
        XCTAssertTrue(encrypted.hasPrefix("R1dTQ3wxfDE0MzQwf"))
    }
}

class SwiftPGEncrypt {
    enum Error: Swift.Error {
      case invalidKey(String)
    }
    
    func setKey(_ key: String) throws {
        if !key.hasPrefix("***") || !key.hasSuffix("***") {
            throw Error.invalidKey("Key is not valid. Should start and end with '***'")
        }
    }
}

class SwiftPGEncryptTest: XCTestCase {
    func testInvalidKey() throws {
        XCTAssertThrowsError(try SwiftPGEncrypt().setKey("invalid"), "should be invalid") { error in
            if case let .invalidKey(message) = error as? SwiftPGEncrypt.Error {
                XCTAssertEqual(message, "Key is not valid. Should start and end with '***'")
            } else {
                XCTFail("should be invalid key error")
            }
        }
    }
}
