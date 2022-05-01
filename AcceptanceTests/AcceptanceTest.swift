//
//  AcceptanceTests.swift
//  AcceptanceTests
//
//  Created by Paul Zabelin on 4/29/22.
//

import XCTest
import EncryptCard
import CryptoSwift
import SwiftyRSA

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
    
    func testDecryptUsingPrivateKey() throws {
        let pemUrl = try url(file: "example-private-key.txt")
        let permString = try XCTUnwrap(String(contentsOf: pemUrl))
        let privateKey = try PrivateKey(pemEncoded: permString)
        XCTAssertNotNil(privateKey)

        let keyUrl = try url(file: "example-payment-gateway-key.txt")
        let card = PGKeyedCard(cardNumber: "4111111111111111", expirationDate: "10/25", cvv: "123")
        let encrypt = PGEncrypt()
        let key = try String(contentsOf: keyUrl)
        encrypt.setKey(key)
        let encrypted = encrypt.encrypt(card, includeCVV: true)!
        
        
        let decodedData = try XCTUnwrap(Data(base64Encoded: encrypted))
        let decodedString = try XCTUnwrap(String(data: decodedData, encoding: .ascii))
        let components = decodedString.components(separatedBy: "|")
        XCTAssertEqual(6, components.count)
        XCTAssertEqual("GWSC", components[0], "format specifier")
        XCTAssertEqual("1", components[1], "version")
        XCTAssertEqual("14340", components[2], "key id")
        let aesEncryptedKeyData = try XCTUnwrap(Data(base64Encoded: components[3]))
        XCTAssertEqual(256, aesEncryptedKeyData.count)
        let ivData = try XCTUnwrap(Data(base64Encoded: components[4]))
        XCTAssertEqual(16, ivData.count)
        let cardData = try XCTUnwrap(Data(base64Encoded: components[5]))
        XCTAssertEqual(48, cardData.count)


        let message = EncryptedMessage(data: aesEncryptedKeyData)
        let aesKeyData = try message.decrypted(with: privateKey, padding: .PKCS1).data
        XCTAssertNotNil(aesKeyData)
        let cypher = try AES(key: aesKeyData.bytes, blockMode: CBC(iv: ivData.bytes), padding: .pkcs5)
        XCTAssertNotNil(cypher)
        let decryptedCard = try cypher.decrypt(cardData.bytes)
        let cardString = String(data: Data(decryptedCard), encoding: .ascii)
        XCTAssertEqual(cardString, "ccnumber=4111111111111111&ccexp=10/25&cvv=123")
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
