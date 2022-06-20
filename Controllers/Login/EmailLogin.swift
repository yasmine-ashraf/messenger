//
//  UserTapped.swift
//  Messenger
//
//  Created by Yasmine Ashraf on 17/08/2021.
//

import UIKit
import FirebaseAuth

extension LoginViewController{
    
    @objc func didTapLogin(){
        spinner.startAnimating()
        emailField.resignFirstResponder()
        passwordField.resignFirstResponder()
        guard let email = emailField.text, let pw = passwordField.text, !email.isEmpty, !pw.isEmpty else {
            alertLoginIncomplete()
            return }
        guard pw.count >= 6 else {
            alertLoginIncomplete(message: "Please enter a valid password. Passwords are atleast 6 characters long")
            return
        }
        guard email.isValidEmail() else {
            alertLoginIncomplete(message: "Please Enter a valid email address")
            return
        }
        FirebaseAuth.Auth.auth().signIn(withEmail: email, password: pw, completion: { [weak self] authResult, error in
            guard let strongSelf = self else {
                return }
            guard error == nil, let result = authResult else {
                print("Error retrieving user")
                return
            }
            UserDefaults.standard.setValue(email, forKey: "email")
            let user = result.user
            let safeEmail = DatabaseManager.safeEmail(email: email)
            DatabaseManager.shared.getFullName(path: safeEmail, completion: { result in
                switch result{
                case .success(let data):
                    guard let userData = data as? [String:Any],
                          let firstName = userData["first_name"],
                          let lastName = userData["last_name"] else {
                            return
                            }
                    UserDefaults.standard.setValue("\(firstName) \(lastName)", forKey: "name")
                    NotificationCenter.default.post(name: .didLogInNotfication, object: nil)
                case .failure(let error):
                    print("failed to read data with error: \(error)")
                }
            })
            DatabaseManager.shared.setCurrentEmail(email: email)
            print("Found user \(user)")
            strongSelf.spinner.stopAnimating()
            strongSelf.navigationController?.dismiss(animated: true, completion: nil)
        })
    }
    func alertLoginIncomplete(message: String = "Please enter all information to log in"){
        let alert = UIAlertController(title: "Woops", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    @objc func didTapRegister() {
        let vc = RegisterViewController()
        vc.title = "Create Account"
        navigationController?.pushViewController(vc, animated: true)
    }
}
