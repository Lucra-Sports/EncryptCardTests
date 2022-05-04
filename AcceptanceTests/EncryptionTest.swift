//
//  EncryptionTest.swift
//  AcceptanceTests
//
//  Created by Paul Zabelin on 5/3/22.
//

import XCTest
import CommonCrypto
@testable import EncryptCard
import CryptoSwift
import SwiftyRSA

class EncryptionTest: XCTestCase {
    let input = String(repeating: "😍ABC123☞❀₰℃ℛ«♘☭‱🔓", count: 20)
    let inputData = secureRandom(size: 245)

    func testAesEncrypt() throws {
        let randomKey = AES.randomIV(kCCKeySizeAES256)
        let irandomSeed = AES.randomIV(kCCBlockSizeAES128)
        let encrypted = try aesEncrypt(key: Data(randomKey), seed: Data(irandomSeed), string: input)
        let cypher = try AES(key: randomKey, blockMode: CBC(iv: irandomSeed), padding: .pkcs5)
        let decrypted = try encrypted.decryptBase64ToString(cipher: cypher)
        XCTAssertEqual(decrypted, input)
    }
    func testRsaEncrypt() throws {
        let encrypted = try rsaEncrypt(publicKey: secKey(), data: inputData)
        let message = try EncryptedMessage(base64Encoded: encrypted)
        let decrypted = try message.decrypted(with: privateKey(), padding: .PKCS1).data
        XCTAssertEqual(decrypted, inputData)
    }
    
    func testRsaEncryptRandomization() throws {
        let key = try secKey()
        let first = try rsaEncrypt(publicKey: key, data: inputData)
        let second = try rsaEncrypt(publicKey: key, data: inputData)
        XCTAssertNotEqual(first, second, "even when given same key and input data, output is different")
        try XCTAssertEqual(secKey(), secKey(), "loaded from same certificates keys are equal")
    }
    
    func privateKey() throws -> PrivateKey {
        let pemUrl = try keysUrl(file: "example-private-key.txt")
        let permString = try XCTUnwrap(String(contentsOf: pemUrl))
        return try PrivateKey(pemEncoded: permString)
    }
    
    func secKey() throws -> SecKey {
        let certificateUrl = try keysUrl(file: "example-certificate.cer")
        let certData = try Data(contentsOf: certificateUrl)
        let certificate = try XCTUnwrap(
            SecCertificateCreateWithData(kCFAllocatorDefault, certData as CFData)
        )
        return try XCTUnwrap(SecCertificateCopyKey(certificate))
    }
}
