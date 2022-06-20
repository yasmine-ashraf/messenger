//
//  TextFieldDelegate.swift
//  Messenger
//
//  Created by Yasmine Ashraf on 17/08/2021.
//
import UIKit

extension LoginViewController:UITextFieldDelegate{
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailField{
            passwordField.becomeFirstResponder()
        }
        else if textField == passwordField{
            didTapLogin()
        }
        return true
    }
}

