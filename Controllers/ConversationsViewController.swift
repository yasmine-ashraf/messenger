//
//  ViewController.swift
//  Messenger
//
//  Created by Yasmine Ashraf on 16/08/2021.
//

import UIKit
import FirebaseAuth

final class ConversationsViewController: UIViewController {
    var conversations = [Conversation]()
    var currentEmail: String?
    let tableView: UITableView = {
        let table = UITableView()
        table.register(ConversationTableViewCell.self, forCellReuseIdentifier: ConversationTableViewCell.identifier)
        table.isHidden = true
        return table
    }()
    let noConversationsLabel: UILabel = {
        let label = UILabel()
        label.text = "You don't have any conversations yet."
        label.textAlignment = .center
        label.textColor = .gray
        label.font = .systemFont(ofSize: 21, weight: .medium)
        label.isHidden = true
        return label
    }()
    var spinner:UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView()
        spinner.hidesWhenStopped = true
        return spinner
    }()
    private var loginObserver: NSObjectProtocol?
    override func viewDidLoad() {
        super.viewDidLoad()
        loginObserver = NotificationCenter.default.addObserver(forName: .didLogInNotfication, object: nil, queue: .main, using: { [weak self] _ in
            guard let strongSelf = self else {
                return
            }
            strongSelf.startListeningForConversations()
        })
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: #selector(didTapCompose))
        view.addSubview(tableView)
        view.addSubview(noConversationsLabel)
        view.addSubview(spinner)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.reloadData()
        spinner.startAnimating()
        validateAuth()
        startListeningForConversations()
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        tableView.reloadData()
        spinner.startAnimating()
//        validateAuth()
        startListeningForConversations()
    }
    override func viewDidLayoutSubviews() {
        spinner.center = view.center
        tableView.frame = view.bounds
        noConversationsLabel.frame = view.bounds
    }
    func validateAuth() {
        if FirebaseAuth.Auth.auth().currentUser == nil{
            tableView.reloadData()
            tableView.isHidden = true
            let vc = LoginViewController()
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: false, completion: nil)
        }
        //we need an else in case the app was deleted without logging out
        //Law hasal mashakel remove this:
        else {
            guard let email = FirebaseAuth.Auth.auth().currentUser?.email else
            { return }
            let safeEmail = DatabaseManager.safeEmail(email: email)
            UserDefaults.standard.setValue(safeEmail, forKey: "email")
            DatabaseManager.shared.getFullName(path: safeEmail, completion: { result in
                switch result{
                case .success(let data):
                    guard let userData = data as? [String:Any],
                          let firstName = userData["first_name"],
                          let lastName = userData["last_name"] else {
                        return
                    }
                    UserDefaults.standard.setValue("\(firstName) \(lastName)", forKey: "name")
                case .failure(let error):
                    print("failed to read data with error: \(error)")
                }
            })
        }
    }
    func showConversations() {
        noConversationsLabel.isHidden = true
        tableView.isHidden = false
    }
    func showNoConvos() {
        tableView.isHidden = true
        noConversationsLabel.isHidden = false
    }
    func startListeningForConversations(){
        if let observer = loginObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else { return }
        DatabaseManager.shared.setCurrentEmail(email: email)
        let safeEmail = DatabaseManager.safeEmail(email: email)
        DatabaseManager.shared.getAllConvos(for: safeEmail, completion: { [weak self] result in
            switch result {
            case .success(let conversations):
                guard !conversations.isEmpty else {
                    self?.showNoConvos()
                    return
                }
                self?.conversations = conversations
                DispatchQueue.main.async {
                    self?.showConversations()
                    self?.tableView.reloadData()
                }
            case .failure(_):
                self?.showNoConvos()
            }
        })
        spinner.stopAnimating()
    }
    @objc func didTapCompose(){
        let vc = NewConversationViewController()
        vc.completion = { [weak self] result in
            let currentConvos = self?.conversations
            if let targetConvo = currentConvos?.first(where: {
                $0.otherUserEmail == DatabaseManager.safeEmail(email: result.email)
            }) {
                let vc = ChatViewController(with: targetConvo.otherUserEmail, id: targetConvo.id)
                vc.isNewConvo = false
                vc.title = targetConvo.otherUserName
                vc.navigationItem.largeTitleDisplayMode = .never
                self?.navigationController?.pushViewController(vc, animated: true)
            } else {
                self?.createNewConvo(result: result)
            }
        }
        let navVC = UINavigationController(rootViewController: vc)
        present(navVC, animated: true)
    }
    private func createNewConvo(result: SearchResult) {
        let name = result.name
        let email = result.email
        let safeEmail = DatabaseManager.safeEmail(email: email)
        //Check in database if convo exists for the other user because this current user mightve deleted it earlier
        //to avoid duplicate convos for same users
        DatabaseManager.shared.convoExists(with: safeEmail, completion: { [weak self] result in
            guard let strongSelf = self else {
                return
            }
            switch result {
            case .success(let convoId):
                let vc = ChatViewController(with: safeEmail, id: convoId)
                vc.isNewConvo = false
                vc.title = name
                vc.navigationItem.largeTitleDisplayMode = .never
                strongSelf.navigationController?.pushViewController(vc, animated: true)
            case .failure(_):
                let vc = ChatViewController(with: email, id: nil)
                vc.isNewConvo = true
                vc.title = name
                vc.navigationItem.largeTitleDisplayMode = .never
                strongSelf.navigationController?.pushViewController(vc, animated: true)
            }
        })
    }
}
//MARK: -- Table View
extension ConversationsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return conversations.count
        //ammend
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ConversationTableViewCell.identifier, for: indexPath) as! ConversationTableViewCell
        let model = conversations[indexPath.row]
        cell.configure(with: model)
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let model = conversations[indexPath.row]
        openConvo(model)
    }
    func openConvo(_ model: Conversation){
        let vc = ChatViewController(with: model.otherUserEmail, id: model.id)
        vc.title = model.otherUserName
        vc.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(vc, animated: true)
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120
    }
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete{
            let conversationId = conversations[indexPath.row].id
            self.conversations.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .left)
            DatabaseManager.shared.deleteConvo(conversationId: conversationId, completion: { success in
                if !success {
                    print("Failed to delete")
                }
            })
            tableView.reloadData()
        }
    }
}
