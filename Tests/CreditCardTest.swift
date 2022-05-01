//
//  CreditCardTest.swift
//  
//
//  Created by Paul Zabelin on 4/30/22.
//

import XCTest
import EncryptCard

class CreditCardTest: XCTestCase {
    func testDirectPostString() throws {
        let cardWithCVV = CreditCard(cardNumber: "1", expirationDate: "2", cvv: "3")
        XCTAssertEqual("ccnumber=1&ccexp=2&cvv=3", cardWithCVV.directPostString())
        XCTAssertEqual("ccnumber=1&ccexp=2", cardWithCVV.directPostString(includeCVV: false))
        XCTAssertEqual("ccnumber=4&ccexp=5", CreditCard(cardNumber: "4", expirationDate: "5").directPostString())
    }
}
