//
//  ChatViewController.swift
//  Messenger
//
//  Created by Yasmine Ashraf on 18/08/2021.
//
import UIKit
import MessageKit


class ChatViewController: MessagesViewController {
    var spinner: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView()
        spinner.hidesWhenStopped = true
        return spinner
    }()
    var messages = [Message]()
    var fromGallery = false
    var sender: Sender? {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return nil }
        let safeEmail = DatabaseManager.safeEmail(email: email)
        let sender = Sender(displayName: "Me", senderId: safeEmail, photoURL: "")
        return sender
    }
    var senderPhotoUrl: URL?
    var isGallery = false
    var otherUserPhotoUrl: URL?
    public var isNewConvo = false
    public let otherUserEmail: String
    var conversationId: String?
    public static var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .long
        formatter.locale = .current
        return formatter
    }()
    init(with email: String, id: String?) {
        //exception mn gher nib wel bundle, w lazem self.otherUserEmail abl calling the super
        self.conversationId = id
        self.otherUserEmail = email
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messagesCollectionView.messageCellDelegate = self
        messagesCollectionView.addSubview(spinner)
        messageInputBar.delegate = self
        setupInputButton()
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        messageInputBar.inputTextView.becomeFirstResponder()
        if let conversationId = conversationId {
            listenForMessages(id: conversationId)
        }
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        spinner.center = messagesCollectionView.center
    }
    func listenForMessages(id: String) {
        spinner.startAnimating()
        DatabaseManager.shared.getAllMessagesForConversation(with: id, completion: { [weak self] result in
            switch result {
            case .success(let messages):
                guard !messages.isEmpty else {
                    return
                }
                self?.messages = messages
                DispatchQueue.main.async {
                    self?.messagesCollectionView.reloadDataAndKeepOffset()
                    self?.messagesCollectionView.scrollToLastItem()
                }
            case .failure(let error):
                print("Error getting messages: \(error)")
            }
        })
        spinner.stopAnimating()
    }
}
