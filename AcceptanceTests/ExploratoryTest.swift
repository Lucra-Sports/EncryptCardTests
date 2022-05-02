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
            XCTAssertEqual(SecCopyErrorMessageString(OSStatus(nsError.code), nil) as String?,
                           "Function or operation not implemented.")
        }
        XCTAssertNil(newKey)
    }
}
