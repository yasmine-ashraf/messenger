//
//  UserTapped.swift
//  Messenger
//
//  Created by Yasmine Ashraf on 17/08/2021.
//

import UIKit
import FirebaseAuth

extension RegisterViewController{
    
    @objc func didTapChangeProfilePic() {
        presentPhotoActionSheet()
    }
    
    @objc func didTapRegister(){
        spinner.startAnimating()
        firstNameField.resignFirstResponder()
        lastNameField.resignFirstResponder()
        emailField.resignFirstResponder()
        passwordField.resignFirstResponder()
        guard let firstName = firstNameField.text, let lastName = lastNameField.text, let email = emailField.text, let pw = passwordField.text, !firstName.isEmpty, !lastName.isEmpty, !email.isEmpty, !pw.isEmpty else {
            alertRegisterIncomplete()
            return }
        guard pw.count >= 6 else {
            alertRegisterIncomplete(message: "Please enter a valid password. Passwords are atleast 6 characters long")
            return
        }
        guard email.isValidEmail() else {
            alertRegisterIncomplete(message: "Please Enter a valid email address")
            return
        }
        
        //Firebase log in
        DatabaseManager.shared.userExists(with: email, completion: { [weak self] exists in
            guard let strongSelf = self else {
                return }
            guard !exists else {
                strongSelf.alertRegisterIncomplete(message: "Email already exists. Please enter a new email or log in")
                return }
            
            FirebaseAuth.Auth.auth().createUser(withEmail: email, password: pw, completion: { authResult, error in
               
                guard error == nil, authResult != nil else {
                    print("Error creating user")
                    return
                }
                UserDefaults.standard.setValue(email, forKey: "email")
                UserDefaults.standard.setValue("\(firstName) \(lastName)", forKey: "name")

                let chatUser = ChatAppUser(firstName: firstName, lastName: lastName, emailAddress: email)
                DatabaseManager.shared.insertUser(with: chatUser, completion: { success in
                    if success {
                        //upload image
                        guard let image = strongSelf.imageView.image, let data = image.pngData() else { return }
                        let fileName = chatUser.profilePicFileName
                        StorageManager.shared.uploadProfilePic(with: data, fileName: fileName, completion: { result in
                            switch result {
                            case .success(let downloadURL):
                                UserDefaults.standard.setValue(downloadURL, forKey: "profile_picture_url")
                                UserDefaults.standard.setValue(email, forKey: "email")
                                DatabaseManager.shared.setCurrentEmail(email: email)
                                print("Download URL: \(downloadURL)")
                            case .failure(let error):
                                print("Error uploading pp: \(error)")
                            }
                        })
                    }
                })
                strongSelf.spinner.stopAnimating()
                strongSelf.navigationController?.dismiss(animated: true, completion: nil)
            })
        })
    }
    // --MARK: Alerts
    func alertRegisterIncomplete(message: String = "Please enter all information to create an account"){
        
        let alert = UIAlertController(title: "Woops", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
}
