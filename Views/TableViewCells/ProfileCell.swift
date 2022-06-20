//
//  ProfileCell.swift
//  Messenger
//
//  Created by Yasmine Ashraf on 24/08/2021.
//

import UIKit

class ProfileCell: UITableViewCell {
    static let identifier = "ProfileCell"
    public func setUp(with viewModel: ProfileViewModel) {
        self.textLabel?.text = viewModel.title
        switch viewModel.viewModelType {
        case .info:
           textLabel?.textAlignment = .left
           selectionStyle = .none
           textLabel?.adjustsFontSizeToFitWidth = true
        case .logout:
            textLabel?.textAlignment = .center
            textLabel?.textColor = .red
        }
    }

}
