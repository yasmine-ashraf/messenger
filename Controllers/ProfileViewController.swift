//
//  ProfileViewController.swift
//  Messenger
//
//  Created by Yasmine Ashraf on 16/08/2021.
//

import UIKit
import FirebaseAuth
import FBSDKLoginKit
import SDWebImage

final class ProfileViewController: UIViewController {
    @IBOutlet var tableView: UITableView!
    var spinner:UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView()
        spinner.hidesWhenStopped = true
        return spinner
    }()
    var data = [ProfileViewModel]()
    let headerView = UIView()
    let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.borderWidth = 3
        imageView.layer.borderColor = UIColor.white.cgColor
        imageView.backgroundColor = .systemBackground
        imageView.layer.cornerRadius = 100
        imageView.layer.masksToBounds = true
        return imageView
    }()
    private var loginObserver: NSObjectProtocol?
    override func viewDidLoad() {
        super.viewDidLoad()
        loginObserver = NotificationCenter.default.addObserver(forName: .didLogInNotfication, object: nil, queue: .main, using: { [weak self] _ in
            guard let strongSelf = self else {
                return
            }
            strongSelf.refresh()
        })
        tableView.register(ProfileCell.self, forCellReuseIdentifier: ProfileCell.identifier )
        data.append(ProfileViewModel(viewModelType: .info, title: "Name: \(UserDefaults.standard.string(forKey: "name") ?? "No Name")", handler: nil))
        data.append(ProfileViewModel(viewModelType: .info, title: "Email: \(UserDefaults.standard.string(forKey: "email") ?? "No Email")", handler: nil))
        data.append(ProfileViewModel(viewModelType: .info, title: " ", handler: nil))
        data.append(ProfileViewModel(viewModelType: .logout, title: "Log Out", handler: { [weak self] in
            guard let strongSelf = self else { return }
            let alert = UIAlertController(title: "Confirm", message: "Are you sure you want to log out?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "Log Out", style: .destructive, handler: { _ in
                UserDefaults.standard.setValue(nil, forKey: "email")
                UserDefaults.standard.setValue(nil, forKey: "name")
//                self?.data.removeAll()
                strongSelf.dismiss(animated: true, completion: nil)
                //fb logout
                FBSDKLoginKit.LoginManager().logOut()
                
                do {
                    try FirebaseAuth.Auth.auth().signOut()
                    let vc = LoginViewController()
                    let nav = UINavigationController(rootViewController: vc)
                    nav.modalPresentationStyle = .fullScreen
                    strongSelf.present(nav, animated: true, completion: nil)
                } catch{
                    print("Failed to log out")
                }
            }))
            strongSelf.present(alert, animated: true)
        }))
        tableView.delegate = self
        tableView.dataSource = self
        spinner.center = view.center
        headerView.frame = CGRect(x: 0, y: 0, width: self.view.width, height: 300)
        headerView.backgroundColor = .link
        imageView.frame = CGRect(x: (headerView.width-200)/2, y: (headerView.height-200)/2, width: 200, height: 200)
        headerView.addSubview(imageView)
        tableView.addSubview(spinner)
        tableView.tableHeaderView = headerView
        guard let email = UserDefaults.standard.string(forKey: "email") else {
            return
        }
        let safeEmail = DatabaseManager.safeEmail(email: email)
        let path = "images/\(safeEmail)_profile_picture.png"
        StorageManager.shared.downloadURL(for: path, completion: { [weak self] result in
            switch result{
            case .success(let url):
                DispatchQueue.main.async {
                    self?.imageView.sd_setImage(with: url, completed: nil)
                }
            case .failure(let error):
                print("failed to get image url: \(error)")
            }
        })
        tableView.reloadData()
    }
    func refresh() {
        data[0] = ProfileViewModel(viewModelType: .info, title: "Name: \(UserDefaults.standard.string(forKey: "name") ?? "No Name")", handler: nil)
        data[1] = ProfileViewModel(viewModelType: .info, title: "Email: \(UserDefaults.standard.string(forKey: "email") ?? "No Email")", handler: nil)
        guard let email = UserDefaults.standard.string(forKey: "email") else {
            return
        }
        let safeEmail = DatabaseManager.safeEmail(email: email)
        let path = "images/\(safeEmail)_profile_picture.png"
        StorageManager.shared.downloadURL(for: path, completion: { [weak self] result in
            switch result{
            case .success(let url):
                DispatchQueue.main.async {
                    self?.imageView.sd_setImage(with: url, completed: nil)
                }
            case .failure(let error):
                print("failed to get image url: \(error)")
            }
        })
        tableView.reloadData()
    }
}

extension ProfileViewController: UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let viewModel = data[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: ProfileCell.identifier, for: indexPath) as! ProfileCell
        cell.setUp(with: viewModel)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        data[indexPath.row].handler?()
    }
}
