//
//  MessageStringFromKind.swift
//  Messenger
//
//  Created by Yasmine Ashraf on 25/08/2021.
//

import Foundation
extension DatabaseManager {
    func messageStringFromKind(message: Message) -> String {
        var messageString = ""
        switch message.kind {
        case .text(let messageText):
            messageString = messageText
            break
        case .attributedText(_):
            break
        case .photo(let mediaItem):
            if let targetUrlString = mediaItem.url?.absoluteString{
                messageString = targetUrlString
            }
            break
        case .video(let mediaItem):
            if let targetUrlString = mediaItem.url?.absoluteString{
                messageString = targetUrlString
            }
            break
        case .location(let locationData):
            let location = locationData.location
            messageString = "\(location.coordinate.longitude),\(location.coordinate.latitude)"
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
        return messageString
    }
}
