//
//  NewConvo1sttime.swift
//  Messenger
//
//  Created by Yasmine Ashraf on 25/08/2021.
//

import Foundation
extension DatabaseManager {
    //Create the new conversation for both users
    ///Creates a new conversation with target use email and first message sent
    public func createNewConvo(with otherUserEmail: String, otherUserName: String, firstMessage: Message, completion: @escaping (_ status: Bool, _ conversationId: String?) -> Void) {
        guard let currentEmail = UserDefaults.standard.string(forKey: "email"),
              let currentName = UserDefaults.standard.value(forKey: "name") as? String else {
            return }
        let safeEmail = DatabaseManager.safeEmail(email: currentEmail)
        let ref = database.child("\(safeEmail)")
        ref.observeSingleEvent(of: .value, with: { [weak self] snapshot in
            guard var userNode = snapshot.value as? [String:Any] else {
                completion(false, nil)
                print("User not found")
                return
            }
            let messageDate = firstMessage.sentDate
            let dateString = ChatViewController.dateFormatter.string(from: messageDate)
            var message = ""
            switch firstMessage.kind{
            case .text(let messageText):
                message = messageText
            case .attributedText(_):
                break
            case .photo(let mediaItem):
                if let targetUrlString = mediaItem.url?.absoluteString{
                    message = targetUrlString
                }
                break
            case .video(let mediaItem):
                if let targetUrlString = mediaItem.url?.absoluteString{
                    message = targetUrlString
                }
                break
            case .location(let locationData):
                let location = locationData.location
                message = "\(location.coordinate.longitude),\(location.coordinate.latitude)"
                break
            case .emoji(_):
                break
            case .audio(_):
                break
            case .contact(_):
                break
            case .linkPreview(_):
                break
            case .custom(_):
                break
            }
            let conversationID = "conversation_\(firstMessage.messageId)"
            let newConversationData: [String:Any] = [
                "id": conversationID,
                "other_user_email": otherUserEmail,
                "name": otherUserName,
                "creation_date": ChatViewController.dateFormatter.string(from: Date()),
                "latest_message": [
                    "date": dateString,
                    "message": message,
                    "is_read": false,
                    "kind": firstMessage.kind.messageKindString
                ]
            ]
            let recipient_newConversationData: [String:Any] = [
                "id": conversationID,
                "other_user_email": safeEmail,
                "name": currentName,
                "creation_date": ChatViewController.dateFormatter.string(from: Date()),
                "latest_message": [
                    "date": dateString,
                    "message": message,
                    "is_read": false,
                    "kind": firstMessage.kind.messageKindString
                ]
            ]
            //Update recipient conversation entry
            self?.database.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value, with: { [weak self] snapshot in
                if var conversations = snapshot.value as? [[String:Any]] {
                    conversations.append(recipient_newConversationData)
                    self?.database.child("\(otherUserEmail)/conversations").setValue(conversations)
                } else{
                    self?.database.child("\(otherUserEmail)/conversations").setValue([recipient_newConversationData])
                }
            })
            //Update current user conversation entry
            if var conversations = userNode["conversations"] as? [[String:Any]]
            {
                conversations.append(newConversationData)
                userNode["conversations"] = conversations
            } else {
                userNode["conversations"] = [newConversationData]
            }
            ref.setValue(userNode, withCompletionBlock: { [weak self] error, _ in
                guard error == nil else {
                    completion(false, nil)
                    return
                }
                self?.finishCreatingConvo(otherUserName: otherUserName, conversationID: conversationID, firstMessage: firstMessage, completion: completion)
            })
        })
    }
    //Fill main conversation with messages
    func finishCreatingConvo(otherUserName: String, conversationID:String, firstMessage: Message, completion: @escaping (_ status: Bool, _ conversationId: String?) -> Void) {
        let message: String = messageStringFromKind(message: firstMessage)
        guard let currentUserEmail = UserDefaults.standard.string(forKey: "email") else {
            completion(false, nil)
            return }
        let safeEmail = DatabaseManager.safeEmail(email: currentUserEmail)
        let messageDate = firstMessage.sentDate
        let dateString = ChatViewController.dateFormatter.string(from: messageDate)
        let collectionMessage: [String:Any] = [
            "id": firstMessage.messageId,
            "type": firstMessage.kind.messageKindString,
            "content": message,
            "date": dateString,
            "sender_email": safeEmail,
            "is_read": false,
            "name": otherUserName
        ]
        let value: [String:Any] = [
            "messages" : [
                collectionMessage
            ]
        ]
        database.child("\(conversationID)").setValue(value, withCompletionBlock: { error, _ in
            guard error == nil else {
                completion(false, nil)
                return
            }
            completion(true, conversationID)
        })
    }
}
