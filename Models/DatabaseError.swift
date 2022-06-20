//
//  DatabaseError.swift
//  Messenger
//
//  Created by Yasmine Ashraf on 24/08/2021.
//

import Foundation
extension DatabaseManager {
    public enum DatabaseError: Error {
        case failedToFetch
    }
}
