//
//  Encrypt.swift
//  AcceptanceTests
//
//  Created by Paul Zabelin on 4/30/22.
//

import Foundation
import CryptoSwift

public class EncryptCard {
    public enum Error: Swift.Error {
        case invalidKey(String)
        case invalidCertificate
        case invalidCard
        case failedToEncrypt
    }
    
    public init() {}
    
    public var keyId: String?
    public var publicKey: SecKey?
    public var subject: String?
    public var commonName: String?
    static let padding = "***"
    static let format = "GWSC"
    static let version = "1"
    
    public func encrypt(_ string: String) throws -> String {
        guard let publicKey = publicKey, let keyId = keyId else {
            throw Error.invalidKey("key is not set, unable to encrypt")
        }
        let randomKey = AES.randomIV(32)
        let iv = AES.randomIV(16)
        let cypher = try AES(key: randomKey, blockMode: CBC(iv: iv), padding: .pkcs5)
        let encoded = try cypher.encrypt(string.bytes)
        var error: Unmanaged<CFError>?

        let aesKeyData = Data(randomKey)
        if let encryptedKey = SecKeyCreateEncryptedData(
            publicKey,
            .rsaEncryptionPKCS1,
            aesKeyData as CFData,
            &error) {
            var result = Self.format + "|" + Self.version + "|" + keyId
            result += "|" + (encryptedKey as Data).base64EncodedString()
            result += "|" + iv.toBase64()
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
        let keys = key.trimmingCharacters(in: .init(charactersIn: "*"))
            .components(separatedBy: .init(charactersIn: "\\|"))
        keyId = keys.first!
        
        if let keyBody = keys.last,
           let data = Data(base64Encoded: keyBody),
           let certificate = SecCertificateCreateWithData(kCFAllocatorDefault, data as CFData),
           let secKey = SecCertificateCopyKey(certificate),
           SecKeyIsAlgorithmSupported(secKey, .encrypt, .rsaEncryptionPKCS1),
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

