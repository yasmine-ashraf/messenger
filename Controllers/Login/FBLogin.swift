//
//  LoginButtonDelegate.swift
//  Messenger
//
//  Created by Yasmine Ashraf on 17/08/2021.
//

import UIKit
import FacebookLogin
import FBSDKCoreKit
import FirebaseAuth

extension LoginViewController: LoginButtonDelegate {
    func loginButton(_ loginButton: FBLoginButton, didCompleteWith result: LoginManagerLoginResult?, error: Error?) {
        
        self.spinner.startAnimating()
        self.spinner.isHidden = false
        guard let token = result?.token?.tokenString else {
            print("Failed to log in with Facebook")
            return }
        let fbRequest = FBSDKLoginKit.GraphRequest(graphPath: "me", parameters: ["fields":"email, first_name, last_name, picture.type(large)"], tokenString: token, version: nil, httpMethod: .get)
        fbRequest.start(completion: { _, result, error in
            guard let result = result as? [String:Any], error == nil else {
                print("Facebook graph request failed")
                return }
            print("\(result)")
            guard let firstName = result["first_name"] as? String,
                  let lastName = result["last_name"] as? String,
                  let email = result["email"] as? String,
                  let picture = result["picture"] as? [String:Any],
                  let data = picture["data"] as? [String:Any],
                  let picURL = data["url"] as? String else {
                print("Failed to retrieve name and email from fbRequest")
                return }
            DatabaseManager.shared.setCurrentEmail(email: email)
            UserDefaults.standard.setValue(email, forKey: "email")
            UserDefaults.standard.setValue("\(firstName) \(lastName)", forKey: "name")
            DatabaseManager.shared.userExists(with: email, completion: { exists in
                if !exists{
                    let chatUser = ChatAppUser(firstName: firstName, lastName: lastName, emailAddress: email)
                    DatabaseManager.shared.insertUser(with: chatUser, completion: { success in
                        if success {
                            //upload image
                            guard let url = URL(string: picURL) else { return }
                            URLSession.shared.dataTask(with: url, completionHandler: { data, _, _ in
                                guard let data = data else { return }
                                let fileName = chatUser.profilePicFileName
                                StorageManager.shared.uploadProfilePic(with: data, fileName: fileName, completion: { result in
                                    switch result {
                                    case .success(let downloadURL):
                                        UserDefaults.standard.setValue(downloadURL, forKey: "profile_picture_url")
                                        print("Download URL: \(downloadURL)")
                                    case .failure(let error):
                                        print("Error uploading pp: \(error)")
                                    }
                                })
                            }).resume()
                        }
                    })
                }
            })
            let credential = FacebookAuthProvider.credential(withAccessToken: token)
            FirebaseAuth.Auth.auth().signIn(with: credential, completion: { [weak self] authResult, error in
                guard let strongSelf = self else { return }
                guard authResult != nil, error == nil else {
                    return }
                print("Successfully logged in with FB")
                strongSelf.spinner.stopAnimating()
                strongSelf.navigationController?.dismiss(animated: true, completion: nil)
            })
        })
        
        
    }
    
    func loginButtonDidLogOut(_ loginButton: FBLoginButton) {
        //no operation
    }
    
    
}
