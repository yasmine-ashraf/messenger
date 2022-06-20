//
//  StructChatAppUser.swift
//  Messenger
//
//  Created by Yasmine Ashraf on 21/08/2021.
//

struct ChatAppUser {
    let firstName: String
    let lastName: String
    let emailAddress: String
    var safeEmail: String {
        var safeEmail = emailAddress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
    var profilePicFileName:String {
        return "\(safeEmail)_profile_picture.png"
    }
    
}
