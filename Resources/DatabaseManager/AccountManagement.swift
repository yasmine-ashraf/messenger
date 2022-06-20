//
//  AccountManagement.swift
//  Messenger
//
//  Created by Yasmine Ashraf on 25/08/2021.
//

import Foundation

extension DatabaseManager {
    public func setCurrentEmail(email: String) {
        currentEmail = UserDefaults.standard.string(forKey: "email")
    }
    public func getAllUsers (completion: @escaping (Result<[[String:String]], Error>) -> Void) {
        database.child("users").observeSingleEvent(of: .value, with: { snapshot in
            guard let value = snapshot.value as? [[String:String]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            completion(.success(value))
        })
    }
    ///Inserts a new user to the Database
    public func insertUser(with user: ChatAppUser, completion: @escaping (Bool) -> (Void)) {
        database.child(user.safeEmail).setValue(["first_name": user.firstName, "last_name": user.lastName], withCompletionBlock: { [weak self] error, _ in
            guard error == nil else {
                print("Error inserting user to database")
                completion(false)
                return
            }
            self?.database.child("users").observeSingleEvent(of: .value, with: { snapshot in
                if var usersCollection = snapshot.value as? [[String: String]] {
                    let newElement =  ["name": user.firstName + " " + user.lastName,
                                       "email": user.safeEmail
                    ]
                    if !usersCollection.contains(newElement)
                    {
                        usersCollection.append(newElement)
                        self?.database.child("users").setValue(usersCollection, withCompletionBlock: { error, _ in
                            guard error == nil else {
                                completion(false)
                                return }
                            completion(true)
                        }
                        )}
                    else {
                        completion(true)
                    }
                }
                else {
                    let newCollection: [[String:String]] = [
                        ["name": user.firstName + " " + user.lastName,
                         "email": user.safeEmail
                        ]
                    ]
                    self?.database.child("users").setValue(newCollection, withCompletionBlock: { error, _ in
                        guard error == nil else {
                            completion(false)
                            return }
                        completion(true)
                    })
                }
            })
        })
    }
    ///Completion true if user exists in database
    public func userExists (with email: String, completion: @escaping ((Bool) -> Void)){
        let safeEmail = DatabaseManager.safeEmail(email: email)
        database.child(safeEmail).observeSingleEvent(of: .value, with: { snapshot in
            guard let savedEmail =  snapshot.value as? [String: Any], !savedEmail.isEmpty  else {
                completion(false)
                return  }
            completion(true)
        })
    }

    func getFullName(path: String, completion: @escaping (Result<Any, Error>) -> Void) {
        self.database.child("\(path)").observeSingleEvent(of: .value, with: { snapshot in
            guard let value = snapshot.value else {
                completion(.failure(DatabaseError.failedToFetch))
                return }
            completion(.success(value))
        })
    }
}
