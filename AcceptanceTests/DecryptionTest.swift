//
//  DecryptionTest.swift
//  AcceptanceTests
//
//  Created by Paul Zabelin on 5/3/22.
//

import XCTest
import CommonCrypto
@testable import EncryptCard
import CryptoSwift
import SwiftyRSA

class DecryptionTest: XCTestCase {
    let input = String(repeating: "😍ABC123☞❀₰℃ℛ«♘☭‱🔓", count: 5)
    let inputData = secureRandom(size: 245)

    func testAesDecrypt() throws {
        let randomKey = AES.randomIV(kCCKeySizeAES256)
        let randomSeed = AES.randomIV(kCCBlockSizeAES128)
        let encrypted = try AES(key: Data(randomKey), seed: Data(randomSeed)).encrypt(string: input)
        let cypher = try AES(key: randomKey, blockMode: CBC(iv: randomSeed), padding: .pkcs5)
        let decrypted = try encrypted.decryptBase64ToString(cipher: cypher)
        XCTAssertEqual(decrypted, input)
    }
    func testRsaDecrypt() throws {
        let encrypted = try RSA(publicKey: secKey()).encrypt(string: input)
        let decrypted = try EncryptedMessage(base64Encoded: encrypted)
            .decrypted(with: privateKey(), padding: .PKCS1)
            .string(encoding: .utf8)
        XCTAssertEqual(decrypted, input)
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
