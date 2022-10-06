//
//  Utilities.swift
//  cueBoom
//
//  Created by Charles Oxendine on 12/30/19.
//  Copyright © 2019 CueBoom LLC. All rights reserved.
//

import Foundation
import SwiftKeychainWrapper
import CryptoKit
import AuthenticationServices

class Utilities {
    
    static public let images = [UIImage(named: "cat-RB")!, UIImage(named: "cat-rock")!, UIImage(named: "cat-pop")!, UIImage(named: "cat-electronic")!, UIImage(named: "cat-country")!, UIImage(named: "cat-hiphop")!]
    
    static func styleTextField(_ textfield:UITextField) {
        let bottomLine = CALayer()
        bottomLine.frame = CGRect(x: -8, y: textfield.frame.height - 2, width: textfield.frame.width.advanced(by: 30), height: 2)
        bottomLine.backgroundColor = UIColor.init(red: 0/255, green: 0/255, blue: 0/255, alpha: 1).cgColor
        textfield.borderStyle = .none
        textfield.layer.addSublayer(bottomLine)
    }
    
    static func isPasswordValid(_ password : String) -> Bool {
        let passwordTest = NSPredicate(format: "SELF MATCHES %@", "^(?=.*[a-z])(?=.*[$@$#!%*?&])[A-Za-z\\d$@$#!%*?&]{8,}")
        return passwordTest.evaluate(with: password)
    }
    
    static func formatCurrency(amount: Double) -> String{
        let currencyFormatter = NumberFormatter()
        currencyFormatter.usesGroupingSeparator = true
        currencyFormatter.numberStyle = .currency
        // localize to your grouping and decimal separator
        currencyFormatter.locale = Locale.current
        return currencyFormatter.string(from: NSNumber(value: amount))!
    }
    
    static func checkForKeyChainLogin() -> (String?, String?)? {
        let retrievedKeychainEmail: String? = KeychainWrapper.standard.string(forKey: "email")
        let retrievedKeychainPassword: String? = KeychainWrapper.standard.string(forKey: "password")
        
        if retrievedKeychainEmail != nil && retrievedKeychainPassword != nil {
            return (retrievedKeychainEmail, retrievedKeychainPassword)
        } else {
            return nil
        }
    }
    
    static func saveKeychainLoginInfo(email: String, password: String) -> Bool {
        let emailSaveSuccessful: Bool = KeychainWrapper.standard.set(email, forKey: "email")
        let passwordSaveSuccessful: Bool = KeychainWrapper.standard.set(password, forKey: "password")
        
        if emailSaveSuccessful == true && passwordSaveSuccessful == true {
            return true
        } else {
            return false
        }
    }
    
    static func randomNonceString(length: Int = 32) -> String {
      precondition(length > 0)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length

        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }

            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }

                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }

        return result
    }
    
    static func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()

        return hashString
    }
    
    static func getAppleIDProviderRequest(nonce: String) -> ASAuthorizationAppleIDRequest {
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = Utilities.sha256(nonce)

        return request
    }
}
