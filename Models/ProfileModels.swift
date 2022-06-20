//
//  ProfileModels.swift
//  Messenger
//
//  Created by Yasmine Ashraf on 24/08/2021.
//

import Foundation

enum ProfileViewModleType {
    case info, logout
}

struct ProfileViewModel {
    let viewModelType: ProfileViewModleType
    let title: String
    let handler: (() -> ())?
}
