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
      case invalidCertificate
    }
    
    var keyId: String?
    var publicKey: SecKey?
    var subject: String?
    var commonName: String?
    static let padding = "***"
    
    func withoutPrefix(_ string: String) -> String {
        String(string.dropFirst(Self.padding.count))
    }
    func withoutSuffix(_ string: String) -> String {
        String(string.dropLast(Self.padding.count))
    }

    func setKey(_ key: String) throws {
        if !key.hasPrefix(Self.padding) || !key.hasSuffix(Self.padding) {
            throw Error.invalidKey("Key is not valid. Should start and end with '***'")
        }
        let keys = withoutPrefix(withoutSuffix(key)).components(separatedBy: .init(charactersIn: "\\|"))
        keyId = keys[0]
        if let data = Data(base64Encoded: keys[1]),
           let certificate = SecCertificateCreateWithData(kCFAllocatorDefault, data as CFData),
           let secKey = SecCertificateCopyKey(certificate),
           SecKeyIsAlgorithmSupported(secKey, .encrypt, .rsaEncryptionRaw),
           let summary = SecCertificateCopySubjectSummary(certificate) {
            var name: CFString?
            SecCertificateCopyCommonName(certificate, &name)
            if let name = name {
                commonName = name as String
            }
            publicKey = secKey
            subject = summary as String
        } else {
            throw Error.invalidCertificate
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
    
    func testValidKey() throws {
        let key = try! String(contentsOf: URL(fileURLWithPath: "/tmp/key.txt"))
        let encrypt = SwiftPGEncrypt()
        try encrypt.setKey(key)
        XCTAssertEqual("14340", encrypt.keyId)
        XCTAssertEqual("www.safewebservices.com", encrypt.subject)
        XCTAssertEqual("www.safewebservices.com", encrypt.commonName)
        XCTAssertTrue(encrypt.publicKey.debugDescription.contains(
            "SecKeyRef algorithm id: 1, key type: RSAPublicKey, version: 4, block size: 2048 bits"
        ))
    }
}
