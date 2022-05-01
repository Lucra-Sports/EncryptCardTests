//
//  AcceptanceTests.swift
//  AcceptanceTests
//
//  Created by Paul Zabelin on 4/29/22.
//

import XCTest
import EncryptCard
import CryptoSwift

class AcceptanceTest: XCTestCase {
    let bundle = Bundle(for: AcceptanceTest.self)
    let exampleKeyFileName = "example-payment-gateway-key.txt"
    
    func url(file: String) throws -> URL {
        try XCTUnwrap(bundle.url(forResource: file,
                                 withExtension: nil))
    }
                               
    func testConvertingCertificateToPGEncryptKey() throws {
        let cerUrl = try url(file: "example-certificate.cer")
        let cerData = try Data(contentsOf: cerUrl)
        let certificate = try XCTUnwrap(
            SecCertificateCreateWithData(kCFAllocatorDefault, cerData as CFData)
        )
        let summary = try XCTUnwrap(
            SecCertificateCopySubjectSummary(certificate)
        ) as String
        XCTAssertEqual("www.safewebservices.com", summary)
        
        let pgKey = "***14340|" + cerData.base64EncodedString() + "***"
        let pgKeyUrl = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("example-payment-gateway-key.txt")
        try pgKey.write(to: pgKeyUrl, atomically: true, encoding: .ascii)
    }
    func testPGEncrypt() throws {
        let keyUrl = try url(file: exampleKeyFileName)
        let card = PGKeyedCard(cardNumber: "4111111111111111", expirationDate: "10/25", cvv: "123")
        let encrypt = PGEncrypt()
        let key = try String(contentsOf: keyUrl)
        encrypt.setKey(key)
        let encrypted = encrypt.encrypt(card, includeCVV: true)!
        XCTAssertTrue(encrypted.hasPrefix("R1dTQ3wxfDE0MzQwf"))
    }

}

class EncryptTest: XCTestCase {
    func testInvalidKey() throws {
        XCTAssertThrowsError(try Encrypt().setKey("invalid"), "should be invalid") { error in
            if case let .invalidKey(message) = error as? Encrypt.Error {
                XCTAssertEqual(message, "Key is not valid. Should start and end with '***'")
            } else {
                XCTFail("should be invalid key error")
            }
        }
    }
    
    func testValidKey() throws {
        let key = try! String(contentsOf: URL(fileURLWithPath: "/tmp/key.txt"))
        let encrypt = Encrypt()
        try encrypt.setKey(key)
        XCTAssertEqual("14340", encrypt.keyId)
        XCTAssertEqual("www.safewebservices.com", encrypt.subject)
        XCTAssertEqual("www.safewebservices.com", encrypt.commonName)
        XCTAssertTrue(encrypt.publicKey.debugDescription.contains(
            "SecKeyRef algorithm id: 1, key type: RSAPublicKey, version: 4, block size: 2048 bits"
        ))
    }
}
