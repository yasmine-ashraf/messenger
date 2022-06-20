//
//  MessagesDelegateDS.swift
//  Messenger
//
//  Created by Yasmine Ashraf on 25/08/2021.
//

import MessageKit
import SDWebImage

//MARK: Messages delegate/ds
extension ChatViewController: MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate{
    func currentSender() -> SenderType {
        if let sender = sender{
            return sender
        }
        fatalError("Sender is nil, email should be cached but isn't")
    }
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
    }
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        messages.count
    }
    func configureMediaMessageImageView(_ imageView: UIImageView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        guard let message = message as? Message else {
            return
        }
        switch message.kind {
        case .photo(let media):
            guard let imageURL = media.url else {
                return
            }
            imageView.sd_setImage(with: imageURL, completed: nil)
//        case .location(_):
//            print("ha")
//
        default:
            break
        }
    }
    func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        let sender = message.sender
        if let selfSender = self.sender, selfSender.senderId == sender.senderId {
            return .link
        }
        return .secondarySystemBackground
    }
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        guard let selfSender = self.sender else {
            return
        }
        let sender = message.sender
        if sender.senderId == selfSender.senderId {
            if let currentUserPhotoUrl = self.senderPhotoUrl {
                //current user and image already loaded
                avatarView.sd_setImage(with: currentUserPhotoUrl, completed: nil)
            }
            else {
                //current user but still need to fetch image
                guard let currentEmail = UserDefaults.standard.string(forKey: "email") else {
                    return
                }
                let currentSafeEmail = DatabaseManager.safeEmail(email: currentEmail)
                let path = "images/\(currentSafeEmail)_profile_picture.png"
                StorageManager.shared.downloadURL(for: path, completion: { [weak self] result in
                    switch result {
                    case .success(let url):
                        self?.senderPhotoUrl = url
                        DispatchQueue.main.async {
                            avatarView.sd_setImage(with: url, completed: nil)
                        }
                    case.failure(let error):
                        print("failed to download avatar in chat: \(error)")
                    }
                })
            }
        } else {
            //other user
            if let otherUserPhotoUrl = self.otherUserPhotoUrl {
                //other user and image already loaded
                avatarView.sd_setImage(with: otherUserPhotoUrl, completed: nil)
            }
            else {
                //other user and need to load image
                let otherSafeEmail = DatabaseManager.safeEmail(email: self.otherUserEmail)
                let path = "images/\(otherSafeEmail)_profile_picture.png"
                StorageManager.shared.downloadURL(for: path, completion: { [weak self] result in
                    switch result {
                    case .success(let url):
                        self?.otherUserPhotoUrl = url
                        DispatchQueue.main.async {
                            avatarView.sd_setImage(with: url, completed: nil)
                        }
                    case.failure(let error):
                        print("failed to download avatar in chat: \(error)")
                    }
                })
            }
        }
    }
}
