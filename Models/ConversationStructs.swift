//
//  ConversationModels.swift
//  Messenger
//
//  Created by Yasmine Ashraf on 24/08/2021.
//

import Foundation

struct Conversation{
    let id: String
    let otherUserName: String
    let otherUserEmail: String
    let latestMessage: LatestMessage
    let creationDate: String
}
struct LatestMessage {
    let date: String
    let text: String
    let kind: String
}
