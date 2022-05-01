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
    
    struct TestCardAndKey {
        let key: String
        let cardNumber: String
        let expirationDate: String
        let cvv: String?
    }
    
    func verifyDecrypt(usingEncryption: (TestCardAndKey) throws -> String) throws {
        let keyUrl = try url(file: "example-payment-gateway-key.txt")
        let key = try String(contentsOf: keyUrl)
        let testCard = TestCardAndKey(
            key: key,
            cardNumber: "4111111111111111",
            expirationDate: "10/25",
            cvv: "123"
        )
        let encrypted = try usingEncryption(testCard)
        XCTAssertTrue(encrypted.hasPrefix("R1dTQ3wxfDE0MzQwf"))
        
        let cardString = try decrypt(base64: encrypted)
        XCTAssertEqual(cardString,
                       "ccnumber=" + testCard.cardNumber
                       + "&ccexp=" + testCard.expirationDate
                       + (testCard.cvv.flatMap{"&cvv=\($0)"} ?? ""))
    }
    
    func testDecryptPGEncrypt() throws {
        try verifyDecrypt { testCard in
            let card = PGKeyedCard(cardNumber: testCard.cardNumber,
                                   expirationDate: testCard.expirationDate,
                                   cvv: testCard.cvv)
            let encrypt = PGEncrypt()
            encrypt.setKey(testCard.key)
            return try XCTUnwrap(encrypt.encrypt(card, includeCVV: true))
        }
    }
    func testDecryptEncrypt() throws {
        try verifyDecrypt { testCard in
            let encrypt = Encrypt()
            try encrypt.setKey(testCard.key)
            let card = CreditCard(cardNumber: testCard.cardNumber,
                                  expirationDate: testCard.expirationDate,
                                  cvv: testCard.cvv)
            return try encrypt.encrypt(creditCard: card)
        }
    }

    func decrypt(base64 encrypted: String) throws -> String {
        let pemUrl = try url(file: "example-private-key.txt")
        let permString = try XCTUnwrap(String(contentsOf: pemUrl))
        let privateKey = try PrivateKey(pemEncoded: permString)
        XCTAssertNotNil(privateKey)
        
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
        return try XCTUnwrap(String(data: Data(decryptedCard), encoding: .ascii))
    }
}
