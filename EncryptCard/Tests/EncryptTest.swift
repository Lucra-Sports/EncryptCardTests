//
//  EncryptTest.swift
//  
//
//  Created by Paul Zabelin on 4/30/22.
//

import XCTest
import EncryptCard

class EncryptTest: XCTestCase {
    var keyUrl = Bundle.module.url(forResource: "example-payment-gateway-key.txt",
                                   withExtension: nil)!
    func testEncryptString() throws {
        let key = try String(contentsOf: keyUrl)
        let encrypt = Encrypt()
        try encrypt.setKey(key)
        let encrypted = try encrypt.encrypt("sample")
        XCTAssertTrue(encrypted.hasPrefix("R1dTQ3wxfDE0MzQwf"))
    }
    func testSetKeyToValid() throws {
        let key = try String(contentsOf: keyUrl)
        let encrypt = Encrypt()
        try encrypt.setKey(key)
        XCTAssertEqual("14340", encrypt.keyId)
        XCTAssertEqual("www.safewebservices.com", encrypt.subject)
        XCTAssertEqual("www.safewebservices.com", encrypt.commonName)
        XCTAssertTrue(encrypt.publicKey.debugDescription.contains(
            "SecKeyRef algorithm id: 1, key type: RSAPublicKey, version: 4, block size: 2048 bits"
        ))
    }
    func testSetKeyInvalid() throws {
        XCTAssertThrowsError(try Encrypt().setKey("invalid"), "should be invalid") { error in
            if case let .invalidKey(message) = error as? Encrypt.Error {
                XCTAssertEqual(message, "Key is not valid. Should start and end with '***'")
            } else {
                XCTFail("should be invalid key error")
            }
        }
    }
}
