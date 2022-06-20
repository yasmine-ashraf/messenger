//
//  NewConversationViewController.swift
//  Messenger
//
//  Created by Yasmine Ashraf on 16/08/2021.
//

import UIKit

final class NewConversationViewController: UIViewController {
    public var completion: ((SearchResult) -> (Void))?
    var spinner:UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView()
        spinner.hidesWhenStopped = true
        spinner.color = .blue
        return spinner
    }()
    var users = [[String:String]]()
    var results = [SearchResult]()
    var hasFetched = false
    let searchBar:UISearchBar = {
        let bar = UISearchBar()
        bar.placeholder = "Search for users"
        bar.isUserInteractionEnabled = true
        return bar
    }()
    let tableView:UITableView = {
       let table = UITableView()
        table.isHidden = true
        table.register(NewConversationCell.self, forCellReuseIdentifier: NewConversationCell.identifier)
        return table
    }()
    let noResultsLabel: UILabel = {
        let label = UILabel()
        label.text = "No Results Found."
        label.textAlignment = .center
        label.textColor = .lightGray
        label.font = .systemFont(ofSize: 21, weight: .medium)
        label.isHidden = true
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(spinner)
        view.addSubview(tableView)
        view.addSubview(noResultsLabel)
        tableView.delegate = self
        tableView.dataSource = self
        searchBar.delegate = self
        searchBar.enablesReturnKeyAutomatically = true
        view.backgroundColor = .systemBackground
        navigationController?.navigationBar.topItem?.titleView = searchBar
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Cancel", style: .done, target: self, action: #selector(dismissSelf))
        searchBar.becomeFirstResponder()
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
        noResultsLabel.frame = CGRect(x: view.width/4, y: (view.height-200)/2, width: view.width/2, height: 200)
        spinner.center = view.center
    }
    @objc func dismissSelf() {
        dismiss(animated: true, completion: nil)
    }
}

extension NewConversationViewController: UISearchBarDelegate{
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        spinner.startAnimating()
        searchBar.resignFirstResponder()
        guard let text = searchBar.text, !text.isEmpty, !text.replacingOccurrences(of: " ", with: "").isEmpty else {
            return }
        results.removeAll()
        searchUsers(query: text)
    }
    func searchUsers(query: String){
        if hasFetched{
            filterUsers(with: query)
        }
        else{
            DatabaseManager.shared.getAllUsers(completion: { [weak self] result in
                switch result{
                case .success(let usersCollection):
                    self?.hasFetched = true
                    self?.users = usersCollection
                    self?.filterUsers(with: query)
                case .failure(let error):
                    print(error)
                }
            })
        }
    }
    func filterUsers(with term: String){
        guard let currentUserEmail = UserDefaults.standard.string(forKey: "email"), hasFetched else {
            return
        }
        let safeEmail = DatabaseManager.safeEmail(email: currentUserEmail)
        let results: [SearchResult] = users.filter({ element in
            guard let email = element["email"], email != safeEmail, let name = element["name"]?.lowercased() else {
                return false
            }
            return name.hasPrefix(term.lowercased())
        }).compactMap({ element in
            guard let email = element["email"], let name = element["name"] else {
                return nil
            }
            
        return SearchResult(name: name, email: email)
        })
        self.results = results
        updateUI()
    }
    func updateUI() {
        spinner.stopAnimating()
        if results.isEmpty{
            tableView.isHidden = true
            noResultsLabel.isHidden = false
        }
        else {
            noResultsLabel.isHidden = true
            tableView.isHidden = false
            tableView.reloadData()
        }
    }
}

extension NewConversationViewController: UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        results.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = results[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: NewConversationCell.identifier, for: indexPath) as! NewConversationCell
        cell.configure(with: model)
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let targetUserData = results[indexPath.row]
        dismiss(animated: true, completion: { [weak self] in
            self?.completion?(targetUserData)
        })
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 90
    }
    
}
