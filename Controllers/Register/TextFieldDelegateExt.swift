//
//  extensionTextFieldDelegate.swift
//  Messenger
//
//  Created by Yasmine Ashraf on 17/08/2021.
//

import UIKit

extension RegisterViewController:UITextFieldDelegate{
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == firstNameField{
            lastNameField.becomeFirstResponder()
        }
        else if textField == lastNameField{
            emailField.becomeFirstResponder()
        }
        else if textField == emailField{
            passwordField.becomeFirstResponder()
        }
        else if textField == passwordField{
            didTapRegister()
        }
        return true
    }
}
