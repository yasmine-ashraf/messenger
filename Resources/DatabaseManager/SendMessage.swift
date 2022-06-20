//
//  SendMessage.swift
//  Messenger
//
//  Created by Yasmine Ashraf on 25/08/2021.
//

import Foundation


extension DatabaseManager {
    ///Sends a message with target conversation and message
    public func sendMessage(to conversation: String, otherUserEmail: String, name: String, newMessage: Message, completion: @escaping (Bool) -> Void){
        //add new message to messages, update sender & recipient latest message
        guard let myEmail = UserDefaults.standard.string(forKey: "email") else{
            completion(false)
            return
        }
        database.child("\(conversation)/messages").observeSingleEvent(of: .value, with: { [weak self] snapshot in
            guard let strongSelf = self else {
                return
            }
            guard var currentMessages = snapshot.value as? [[String:Any]] else {
                completion(false)
                return
            }
            let message: String = (self?.messageStringFromKind(message: newMessage))!
            let safeEmail = DatabaseManager.safeEmail(email: myEmail)
            let messageDate = newMessage.sentDate
            let dateString = ChatViewController.dateFormatter.string(from: messageDate)
            let newMessageEntry: [String:Any] = [
                "id": newMessage.messageId,
                "type": newMessage.kind.messageKindString,
                "content": message,
                "date": dateString,
                "sender_email": safeEmail,
                "is_read": false,
                "name": name
            ]
            currentMessages.append(newMessageEntry)
            strongSelf.database.child("\(conversation)/messages").setValue(currentMessages, withCompletionBlock: { error , _ in
                guard error == nil else {
                    completion(false)
                    return
                }
                //Finished updating main conversation
                //Now update conversations for users:
                guard let currentName = UserDefaults.standard.string(forKey: "name") else {
                    print("ERROR name was not stored")
                    return
                }
                //Update the latest message to this:
                let updatedValue: [String:Any] = [
                    "date": dateString,
                    "is_read": false,
                    "message": message,
                    "kind": newMessage.kind.messageKindString
                ]
                strongSelf.updateConvosForUser(userSafeEmail: safeEmail, username: name, convoId: conversation, updatedValue: updatedValue, completion: { success in
                    if !success {
                        print("Error updating current user convos")
                        completion(false)
                    }
                    strongSelf.updateConvosForUser(userSafeEmail: otherUserEmail, username: currentName, convoId: conversation, updatedValue: updatedValue, completion: { success in
                        if !success {
                            print("Error updating recipient user convos")
                            completion(false)
                        }
                        completion(true)
                    })
                })
            })
        })
    }
    func updateConvosForUser (userSafeEmail: String, username: String, convoId: String, updatedValue: [String:Any], completion: @escaping (Bool) -> Void) {
        database.child("\(userSafeEmail)/conversations").observeSingleEvent(of: .value, with: { [weak self] snapshot in
            guard let strongSelf = self else {
                return
            }
            var databaseEntryConvos = [[String:Any]]()
            //Search for the existing convo to update it
            if var currentUserConvos = snapshot.value as? [[String:Any]] {
                var position = 0
                var targetConvo: [String:Any]?
                for conversationDictionary in currentUserConvos {
                    if let currentId = conversationDictionary["id"] as? String, currentId == convoId {
                        targetConvo = conversationDictionary
                        break
                    }
                    position += 1
                }
                if var targetConvo = targetConvo {
                    //Convo found
                    targetConvo["latest_message"] = updatedValue
                    currentUserConvos[position] = targetConvo
                    databaseEntryConvos = currentUserConvos
                }
                else {
                    //Reinsert convo. user deleted it
                    let newConvoData: [String:Any] = [
                        "id": convoId,
                        "other_user_email": userSafeEmail,
                        "name": username,
                        "latest_message": updatedValue,
                        "creation_date": ChatViewController.dateFormatter.string(from: Date())
                        
                    ]
                    currentUserConvos.append(newConvoData)
                    databaseEntryConvos = currentUserConvos
                }
            }
            else {
                //Reinsert convo. user deleted it and doesn't have any other convos
                let newConvoData: [String:Any] = [
                    "id": convoId,
                    "other_user_email": userSafeEmail,
                    "name": username,
                    "latest_message": updatedValue,
                    "creation_date": ChatViewController.dateFormatter.string(from: Date())
                ]
                databaseEntryConvos = [newConvoData]
            }
            strongSelf.database.child("\(userSafeEmail)/conversations").setValue(databaseEntryConvos, withCompletionBlock: { error, _ in
                guard error == nil else {
                    completion(false)
                    return
                }
                completion(true)
            })
        })
    }
}
