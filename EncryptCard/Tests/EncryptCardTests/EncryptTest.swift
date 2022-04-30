//
//  EncryptTest.swift
//  
//
//  Created by Paul Zabelin on 4/30/22.
//

import XCTest
import EncryptCard

class EncryptTest: XCTestCase {
    func testEncrypt() throws {
        let key = try! String(contentsOf: URL(fileURLWithPath: "/tmp/key.txt"))
        let encrypt = Encrypt()
        try encrypt.setKey(key)
        let encrypted = try encrypt.encrypt("sample")
        XCTAssertTrue(encrypted.hasPrefix("R1dTQ3wxfDE0MzQwf"))
    }
}
