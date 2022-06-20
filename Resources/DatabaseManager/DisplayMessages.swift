//
//  DisplayMessages.swift
//  Messenger
//
//  Created by Yasmine Ashraf on 25/08/2021.
//

import UIKit
import MessageKit
import CoreLocation
import AVKit

extension DatabaseManager {
    ///Fetches all existing conversations for user with email
    public func getAllConvos(for email:String, completion: @escaping (Result<[Conversation],Error>) -> Void){
        database.child("\(email)/conversations").observe(.value, with: { snapshot in
            guard let value = snapshot.value as? [[String:Any]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            let conversations: [Conversation] = value.compactMap({ dictionary in
                guard let conversationId = dictionary["id"] as? String,
                      let name = dictionary["name"] as? String,
                      let otherUserEmail = dictionary["other_user_email"] as? String,
                      let creationDate = dictionary["creation_date"] as? String,
                      let latestMessage = dictionary["latest_message"] as? [String:Any],
                      let date = latestMessage["date"] as? String,
                      let message = latestMessage["message"] as? String,
                      let kind = latestMessage["kind"] as? String else {
                    return nil
                }
                let latestMessageObject = LatestMessage(date: date, text: message, kind: kind)
                return Conversation(id: conversationId, otherUserName: name, otherUserEmail: otherUserEmail, latestMessage: latestMessageObject, creationDate: creationDate)
            })
            completion(.success(conversations))
        })
    }
    ///Fetches all prevoius messages in a conversation
    public func getAllMessagesForConversation(with id: String, completion: @escaping (Result<[Message],Error>) -> Void){
        database.child("\(id)/messages").observe(.value, with: { [weak self] snapshot in
            guard let value = snapshot.value as? [[String:Any]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            let messages: [Message] = value.compactMap({ dictionary in
                guard let name = dictionary["name"] as? String,
                      let content = dictionary["content"] as? String,
                      let messageId = dictionary["id"] as? String,
                      let dateString = dictionary["date"] as? String,
                      let date = ChatViewController.dateFormatter.date(from: dateString),
                      let senderEmail = dictionary["sender_email"] as? String,
                      let type = dictionary["type"] as? String else {
                        return nil
                }
                var kind: MessageKind?
                if type == "text"{
                    kind = .text(content)
                }
                else if type == "photo" {
                    guard let imageURL = URL(string: content), let placeholder = UIImage(systemName: "plus") else {
                        return nil
                    }
                    let media = Media(url: imageURL, image: nil, placeholderImage: placeholder, size: CGSize(width: 300, height: 300))
                        kind = .photo(media)
                }
                else if type == "video" {
                    guard let videoURL = URL(string: content) else {
                        return nil
                    }
                    guard let placeholder = UIImage(named: "VideoPlaceholder") else {
                        return nil
                    }
//                    AVAsset(url: videoURL).generateThumbnail(completion: { image in
//                        if let thumbnail = image {
//                            placeholder = thumbnail
//                            print("got thumbnail")
//                        }
//                    })
                    let media = Media(url: videoURL, image: nil, placeholderImage: placeholder, size: CGSize(width: 300, height: 300))
                    kind = .video(media)
                }
                else if type == "location" {
                    let locComponent = content.components(separatedBy: ",")
                    guard let long = Double(locComponent[0]), let lat = Double(locComponent[1]) else {
                        return nil
                    }
                    let location = Location(location: CLLocation(latitude: lat, longitude: long), size: CGSize(width: 300, height: 300))
                    kind = .location(location)
                }
                guard let finalKind = kind else {
                    return nil
                }
                let sender = Sender(displayName: name, senderId: senderEmail, photoURL: "")
                return Message(sender: sender, messageId: messageId, sentDate: date, kind: finalKind)
            })
//            completion(.success(messages))
            self?.filterByDate(messages: messages, convoId: id, completion: {
                result in
                switch result {
                case .success(let newMessages):
                    completion(.success(newMessages))
                case .failure(_):
                    completion(.success([Message]()))
                }
            })
        })
    }
    ///Filter messages based on creation date in case user deleted this conversation
    func filterByDate(messages: [Message], convoId: String, completion: @escaping (Result<[Message],Error>) -> Void) {
        var newMessages = [Message]()
        guard let currentEmail = currentEmail else {
            print("Email not stored")
            return
        }
        let safeEmail = DatabaseManager.safeEmail(email: currentEmail)
        database.child("\(safeEmail)/conversations").observeSingleEvent(of: .value, with: { snapshot in
            if let currentUserConvos = snapshot.value as? [[String:Any]] {
                var position = 0
                var targetConvo: [String:Any]?
                for conversationDictionary in currentUserConvos {
                    if let currentId = conversationDictionary["id"] as? String, currentId == convoId {
                        targetConvo = conversationDictionary
                        break
                    }
                    position += 1
                }
                if let targetConvo = targetConvo, let creationDateString = targetConvo["creation_date"] as? String, let creationDate = ChatViewController.dateFormatter.date(from: creationDateString) {
                    for message in messages {
                        let dateObject = message.sentDate
                        if dateObject >= creationDate {
                            newMessages.append(message)
                        }
                    }
                    completion(.success(newMessages))
                    return
                }
            } else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
        })
    }
}
