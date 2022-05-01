//
//  File.swift
//  
//
//  Created by Paul Zabelin on 4/30/22.
//

import Foundation
import XCTest
import Security

class ExploratoryTest: XCTestCase {
    func testErrorPointer() throws {
        var cfErrorPtr: Unmanaged<CFError>?
        let newKey = SecKeyCreateRandomKey(["invalid":"parameters"] as CFDictionary, &cfErrorPtr)
        if let error = cfErrorPtr?.takeRetainedValue() {
            let nsError = error as Error as NSError
            XCTAssertEqual(nsError.domain, NSOSStatusErrorDomain)
            XCTAssertEqual(nsError.code, Int(errSecUnimplemented))
            XCTAssertEqual(nsError.userInfo["NSDescription"] as? String,
                           "Key generation failed, error -4")
            XCTAssertEqual(SecCopyErrorMessageString(OSStatus(nsError.code), nil) as? String,
                           "Function or operation not implemented.")
        }
        XCTAssertNil(newKey)
    }
    func testLoadPublicKey() throws {
        let key = try! String(contentsOf: URL(fileURLWithPath: "/tmp/key.txt"))
        let keys = key.trimmingCharacters(in: .init(charactersIn: "*")).components(separatedBy: .init(charactersIn: "\\|"))
        if let data = Data(base64Encoded: keys[1]),
           let certificate = SecCertificateCreateWithData(kCFAllocatorDefault, data as CFData),
           let secKey = SecCertificateCopyKey(certificate) {
            print(secKey)
            let data = SecCertificateCopyData(certificate) as Data
            try data.write(to: URL(fileURLWithPath: "/tmp/key-to-cert.crt"))
        }
    }
}
