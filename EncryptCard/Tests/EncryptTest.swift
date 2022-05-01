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
    func testDecode() throws {
        let card = CreditCard(cardNumber: "4111111111111111", expirationDate: "10/25", cvv: "123")
        let key = try String(contentsOf: keyUrl)
        let encrypt = Encrypt()
        try encrypt.setKey(key)
        let encrypted = try encrypt.encrypt(creditCard: card)
        XCTAssertTrue(encrypted.hasPrefix("R1dTQ3wxfDE0MzQwf"))
        
        let decodedData = try XCTUnwrap(Data(base64Encoded: encrypted))
        let decodedString = try XCTUnwrap(String(data: decodedData, encoding: .ascii))
        let components = decodedString.components(separatedBy: "|")
        XCTAssertEqual(6, components.count)
        XCTAssertEqual("GWSC", components[0], "format specifier")
        XCTAssertEqual("1", components[1], "version")
        XCTAssertEqual("14340", components[2], "key id")
        let encryptedAESKeyData = try XCTUnwrap(Data(base64Encoded: components[3]))
        XCTAssertEqual(256, encryptedAESKeyData.count)
        let ivData = try XCTUnwrap(Data(base64Encoded: components[4]))
        XCTAssertEqual(16, ivData.count)
        let encryptedCardData = try XCTUnwrap(Data(base64Encoded: components[5]))
        XCTAssertEqual(48, encryptedCardData.count)
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
    func testSetKeyWithoutKeyData() throws {
        XCTAssertThrowsError(try Encrypt().setKey("***123***"), "should be invalid") { error in
            if case .invalidCertificate = error as? Encrypt.Error {
                return
            } else {
                XCTFail("should be invalid key error")
            }
        }
    }
}
