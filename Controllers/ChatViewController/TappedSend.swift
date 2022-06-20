//
//  TappedSend.swift
//  Messenger
//
//  Created by Yasmine Ashraf on 25/08/2021.
//

import UIKit
import InputBarAccessoryView

extension ChatViewController: InputBarAccessoryViewDelegate {
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        spinner.startAnimating()
        guard !text.replacingOccurrences(of: " ", with: "").isEmpty,
              let sender = self.sender,
              let messageId = generateMessageID() else {
            return
        }
        print("Sending: \(text)")
        let message = Message(sender: sender, messageId: messageId, sentDate: Date(), kind: .text(text))
        if isNewConvo {
            DatabaseManager.shared.createNewConvo(with: otherUserEmail, otherUserName: self.title ?? "User", firstMessage: message, completion: { [weak self] success, id in
                if success, let id =  id {
                    print("Message sent")
                    self?.isNewConvo = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self?.listenForMessages(id: id)
                    }
                }
                else {
                    print("Failed to send")
                }
            })
        }
        else {
            guard let conversationId = conversationId, let name = self.title else {
                return
            }
            DatabaseManager.shared.sendMessage(to: conversationId, otherUserEmail: otherUserEmail, name: name, newMessage: message, completion: { [weak self] success in
                if success {
                    print("message sent")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.75) {
                        self?.listenForMessages(id: conversationId)
                    }
                }
                else {
                    print("failed to send message")
                }
            })
        }
        self.messageInputBar.inputTextView.text = nil
        spinner.stopAnimating()
    }
    func generateMessageID() -> String? {
        guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String else { return nil }
        let safeEmail = DatabaseManager.safeEmail(email: currentUserEmail)
        let dateString = ChatViewController.dateFormatter.string(from: Date())
        let newIdentifier = "\(otherUserEmail)_\(safeEmail)_\(dateString)"
        print("Created ID: \(newIdentifier)")
        return newIdentifier
    }
}

