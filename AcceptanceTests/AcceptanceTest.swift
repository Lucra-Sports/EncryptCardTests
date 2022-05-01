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
    func url(file: String) throws -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("EncryptCard/Tests")
            .appendingPathComponent(file)
    }
                               
    func testCertificate() throws {
        let cerUrl = try url(file: "example-certificate.cer")
        let cerData = try Data(contentsOf: cerUrl)
        let certificate = try XCTUnwrap(
            SecCertificateCreateWithData(kCFAllocatorDefault, cerData as CFData)
        )
        let summary = try XCTUnwrap(
            SecCertificateCopySubjectSummary(certificate)
        ) as String
        XCTAssertEqual("www.safewebservices.com", summary)
    }
    func testPGEncrypt() throws {
        let keyUrl = try url(file: "example-payment-gateway-key.txt")
        let card = PGKeyedCard(cardNumber: "4111111111111111", expirationDate: "10/25", cvv: "123")
        let encrypt = PGEncrypt()
        let key = try String(contentsOf: keyUrl)
        encrypt.setKey(key)
        let encrypted = encrypt.encrypt(card, includeCVV: true)!
        XCTAssertTrue(encrypted.hasPrefix("R1dTQ3wxfDE0MzQwf"))
    }
}
