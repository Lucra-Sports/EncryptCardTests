//
//  CreditCard.swift
//  AcceptanceTests
//
//  Created by Paul Zabelin on 4/30/22.
//

import Foundation

public struct CreditCard {
    let cardNumber: String
    let expirationDate: String
    let cvv: String?
    
    public init(cardNumber: String, expirationDate: String, cvv: String? = nil) {
        self.cardNumber = cardNumber
        self.expirationDate = expirationDate
        self.cvv = cvv
    }
    
    public func directPostString(includeCVV: Bool = true) -> String{
        var result = "ccnumber=" + cardNumber + "&ccexp=" + expirationDate;
        if includeCVV, let cvv = cvv {
            result += "&cvv=" + cvv
        }
        return result
    }
}
