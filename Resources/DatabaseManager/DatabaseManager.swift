//
//  DatabaseManager.swift
//  Messenger
//
//  Created by Yasmine Ashraf on 17/08/2021.
//

import FirebaseDatabase
import MessageKit
import UIKit
import CoreLocation

/// Manager object to read and write data to real time firebase database
class DatabaseManager {
    static let shared = DatabaseManager()
    public var currentEmail: String?
    let database = Database.database().reference()
    static func safeEmail(email:String) -> String {
        var safeEmail = email.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
}

extension DatabaseManager {
 
    public func deleteConvo(conversationId: String, completion: @escaping (Bool) -> Void){
        guard let email = UserDefaults.standard.string(forKey: "email") else {
            return
        }
        let safeEmail = DatabaseManager.safeEmail(email: email)
        let ref = database.child("\(safeEmail)/conversations")
        ref.observeSingleEvent(of: .value, with: { snapshot in
            if var conversations = snapshot.value as? [[String:Any]] {
                var positionToRemove = 0
                for conversation in conversations{
                    if let id = conversation["id"] as? String, id == conversationId {
                        break
                    }
                    positionToRemove += 1
                }
                conversations.remove(at: positionToRemove)
                ref.setValue(conversations, withCompletionBlock: { error, _ in
                    guard error == nil else {
                        completion(false)
                        return }
                    print("Successfully removed convo")
                    completion(true)
                })
            }
            
        })
    }
    public func convoExists(with targertRecipientEmail: String, completion: @escaping (Result<String, Error>) -> Void) {
        let safeRecipientEmail = DatabaseManager.safeEmail(email: targertRecipientEmail)
        guard let selfEmail = UserDefaults.standard.string(forKey: "email") else {
            return
        }
        let safeSelfEmail = DatabaseManager.safeEmail(email: selfEmail)
        database.child("\(safeRecipientEmail)/conversations").observeSingleEvent(of: .value, with: { snapshot in
            guard let collection = snapshot.value as? [[String:Any]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            if let conversation = collection.first(where: {
                guard let targetSenderEmail = $0["other_user_email"] as? String else {
                    return false
                }
                return targetSenderEmail == safeSelfEmail
            }) {
                guard let id = conversation["id"] as? String else {
                    completion(.failure(DatabaseError.failedToFetch))
                    return
                }
                completion(.success(id))
                return
            }
            completion(.failure(DatabaseError.failedToFetch))
            return
            
        })
    }
}
extension DatabaseManager {
    //Haven't used yet
    /// Returns dictionary node at child path
    public func getDataFor(path: String, completion: @escaping (Result<Any, Error>) -> Void) {
        database.child("\(path)").observeSingleEvent(of: .value) { snapshot in
            guard let value = snapshot.value else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            completion(.success(value))
        }
    }
}
