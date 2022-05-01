//
//  Encrypt.swift
//  AcceptanceTests
//
//  Created by Paul Zabelin on 4/30/22.
//

import Foundation
import CryptoKit
import CryptoSwift

public class Encrypt {
    public enum Error: Swift.Error {
        case invalidKey(String)
        case invalidCertificate
        case invalidCard
        case failedToEncrypt
    }
    
    public init() {
        
    }
    
    public var keyId: String?
    public var publicKey: SecKey?
    public var subject: String?
    public var commonName: String?
    static let padding = "***"
    static let format = "GWSC"
    static let version = "1"
    static let size: SymmetricKeySize = .bits256
    
    func withoutPrefix(_ string: String) -> String {
        String(string.dropFirst(Self.padding.count))
    }
    func withoutSuffix(_ string: String) -> String {
        String(string.dropLast(Self.padding.count))
    }
    
    public func encrypt(_ string: String) throws -> String {
        guard let publicKey = publicKey else {
            throw Error.invalidKey("key is not set, unable to encrypt")
        }
        let aesKey = "12345678901234567890123456789012"
        let ivString = "1234567890123456"
        let cypher = try AES(key:aesKey, iv:ivString, padding: .pkcs5)
        let encoded = try cypher.encrypt(string.bytes)
        var error: Unmanaged<CFError>?

        if let aesKeyData = aesKey.data(using: .ascii),
           let encryptedKey = SecKeyCreateEncryptedData(
            publicKey,
            .rsaEncryptionPKCS1,
            aesKeyData as CFData,
            &error) {
            var result = Self.format + "|" + Self.version + "|" + keyId!
            result += "|" + (encryptedKey as Data).base64EncodedString()
            result += "|" + ivString.bytes.toBase64()
            result += "|" + encoded.toBase64()
            return result.bytes.toBase64()
        } else {
            if let error = error?.takeRetainedValue() {
                throw error as Swift.Error
            }
            throw Error.failedToEncrypt
        }
    }
    
    public func encrypt(creditCard: CreditCard, includeCVV: Bool = true) throws -> String {
        try encrypt(creditCard.directPostString(includeCVV: includeCVV))
    }

    public func setKey(_ key: String) throws {
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

