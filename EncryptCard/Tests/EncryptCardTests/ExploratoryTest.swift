//
//  File.swift
//  
//
//  Created by Paul Zabelin on 4/30/22.
//

import Foundation
import XCTest

class ExploratoryTest: XCTestCase {
    func testErrorPointer() throws {
        var cfErrorPtr: Unmanaged<CFError>?
        let newKey = SecKeyCreateRandomKey(["invalid":"parameters"] as CFDictionary, &cfErrorPtr)
        if let error = cfErrorPtr?.takeRetainedValue() {
            let nsError = error as Error as NSError
            XCTAssertEqual(nsError.domain, NSOSStatusErrorDomain)
            XCTAssertEqual(nsError.code, Int(errSecParam))
            XCTAssertEqual(nsError.userInfo["NSDescription"] as? String,
                           "failed to generate asymmetric keypair")
            XCTAssertEqual(SecCopyErrorMessageString(OSStatus(nsError.code), nil) as? String,
                           "One or more parameters passed to a function were not valid.")
        }
        XCTAssertNil(newKey)
    }
}
