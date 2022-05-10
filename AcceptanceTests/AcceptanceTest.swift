//
//  AcceptanceTests.swift
//  AcceptanceTests
//
//  Created by Paul Zabelin on 4/29/22.
//

import XCTest
@testable import EncryptCard
import CryptoSwift
import SwiftyRSA

class AcceptanceTest: XCTestCase {
    func testDecryptPGEncrypt() throws {
        try verifyEncryptedCardDecrypted { card, key in
            let card = PGKeyedCard(cardNumber: card.cardNumber,
                                   expirationDate: card.expirationDate,
                                   cvv: card.cvv)
            let encrypt = PGEncrypt()
            encrypt.setKey(key)
            return try XCTUnwrap(encrypt.encrypt(card, includeCVV: true))
        }
    }
    func testDecryptEncrypt() throws {
        try verifyEncryptedCardDecrypted { card, key in
            let encrypt = try EncryptCard(key: key)
            return try encrypt.encrypt(creditCard: card)
        }
    }
    func testSameOutputForSameSeedExceptAesKeysThatWereRSAencrypted() throws {
        let card = CreditCard(
            cardNumber: "4111111111111111",
            expirationDate: "10/25",
            cvv: "123"
        )
        let pgCard = PGKeyedCard(cardNumber: card.cardNumber,
                               expirationDate: card.expirationDate,
                               cvv: card.cvv)

        let oldEncrypt = PGEncrypt()
        let keyUrl = try keysUrl(file: "example-payment-gateway-key.txt")
        let key = try String(contentsOf: keyUrl)
        oldEncrypt.setKey(key)
        let oldOutput = try XCTUnwrap(oldEncrypt.encrypt(pgCard, includeCVV: true))
        let oldOutput2 = try XCTUnwrap(oldEncrypt.encrypt(pgCard, includeCVV: true))
        XCTAssertNotEqual(oldOutput, oldOutput2,
                          "same data encrypted produces different output")

        let pemUrl = try keysUrl(file: "example-private-key.txt")
        let permString = try XCTUnwrap(String(contentsOf: pemUrl))
        let privateKey = try PrivateKey(pemEncoded: permString)
        XCTAssertNotNil(privateKey)
        
        let decodedData = try XCTUnwrap(Data(base64Encoded: oldOutput))
        let decodedString = try XCTUnwrap(String(data: decodedData, encoding: .ascii))
        let oldComponents = decodedString.components(separatedBy: "|")
        let aesEncryptedKeyData = try XCTUnwrap(Data(base64Encoded: oldComponents[3]))
        let ivData = try XCTUnwrap(Data(base64Encoded: oldComponents[4]))
        XCTAssertEqual(ivData.count, 16)
        let message = EncryptedMessage(data: aesEncryptedKeyData)
        let oldAesKeyData = try message.decrypted(with: privateKey, padding: .PKCS1).data

        let newEncrypt = try EncryptCard(key: key)
        newEncrypt.createPrivateEncryptor = { AES(key: oldAesKeyData, seed: ivData) }
        let newOutput = try newEncrypt.encrypt(creditCard: card)
        XCTAssertEqual(try decrypt(base64: newOutput),
                       try decrypt(base64: oldOutput),
                       "decrypted output is the same")
        XCTAssertNotEqual(newOutput, oldOutput, "different output due to random padding")
        let newDecoded = try XCTUnwrap(String(
            data: try XCTUnwrap(Data(base64Encoded: newOutput)), encoding: .ascii)
        )
        let newComponents = newDecoded.components(separatedBy: "|")
        for (index, oldComponent) in oldComponents.enumerated() {
            if index == 3 {
                XCTAssertNotEqual(newComponents[index], oldComponent, "encrypted AES keys")
            } else {
                XCTAssertEqual(newComponents[index], oldComponent, "other data is the same")
            }
        }
        let newAesKeyEncrypted = try XCTUnwrap(Data(base64Encoded: newComponents[3]))
        let newMessage = EncryptedMessage(data: newAesKeyEncrypted)
        let newAesKeyData = try newMessage.decrypted(with: privateKey, padding: .PKCS1).data
        XCTAssertEqual(newAesKeyData, oldAesKeyData,
                       "same AES key encrypted differently by RSA")
    }
    
    func testCertificate() throws {
        let cerUrl = try keysUrl(file: "example-certificate.cer")
        let cerData = try Data(contentsOf: cerUrl)
        let certificate = try XCTUnwrap(
            SecCertificateCreateWithData(kCFAllocatorDefault, cerData as CFData)
        )
        let summary = try XCTUnwrap(
            SecCertificateCopySubjectSummary(certificate)
        ) as String
        XCTAssertEqual("www.safewebservices.com", summary)
    }
    
    func verifyEncryptedCardDecrypted(usingEncryption: (CreditCard, String) throws -> String) throws {
        let keyUrl = try keysUrl(file: "example-payment-gateway-key.txt")
        let key = try String(contentsOf: keyUrl)
        let testCard = CreditCard(
            cardNumber: "4111111111111111",
            expirationDate: "10/25",
            cvv: "123"
        )
        let encrypted = try usingEncryption(testCard, key)
        XCTAssertTrue(encrypted.hasPrefix("R1dTQ3wxfDE0MzQwf"))
        
        let cardString = try decrypt(base64: encrypted)
        XCTAssertEqual(cardString, testCard.directPostString())
    }
    
    func decrypt(base64 encrypted: String) throws -> String {
        let pemUrl = try keysUrl(file: "example-private-key.txt")
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
        XCTAssertEqual(aesKeyData.count, 32)
        let cypher = try AES(key: aesKeyData.bytes, blockMode: CBC(iv: ivData.bytes), padding: .pkcs5)
        let decryptedCard = try cypher.decrypt(cardData.bytes)
        return try XCTUnwrap(String(data: Data(decryptedCard), encoding: .ascii))
    }
}

func keysUrl(file: String) throws -> URL {
    Bundle(for: AcceptanceTest.self).bundleURL
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appendingPathComponent("SourcePackages/checkouts/EncryptCard/Tests/keys")
        .appendingPathComponent(file)
}
