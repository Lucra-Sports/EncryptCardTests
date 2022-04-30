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
        let key = SymmetricKey(size: Self.size)
        if let data = string.data(using: .ascii) {
            let sealed = try AES.GCM.seal(data, using: key)
            return sealed.ciphertext.base64EncodedString()
        } else {
            throw Error.invalidCard
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

