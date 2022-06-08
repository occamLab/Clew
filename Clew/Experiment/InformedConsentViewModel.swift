//
//  InformedConsentViewModel.swift
//  LidarCane
//
//  Created by Paul Ruvolo on 3/4/21.
//

import SwiftUI

class InformedConsentViewModel: ObservableObject {
    @Published var userEmail:String=""{didSet {
        print("Typed...")
        isValidEmail(userEmail)
    }}
    @Published var didEnterValidEmail = false

    func isValidEmail(_ email: String) {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        didEnterValidEmail = !email.isEmpty && emailPred.evaluate(with: email)
    }
}
