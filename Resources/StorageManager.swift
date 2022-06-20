//
//  StorageManager.swift
//  Messenger
//
//  Created by Yasmine Ashraf on 19/08/2021.
//

import Foundation
import FirebaseStorage

final class StorageManager {
    static let shared = StorageManager()
    let storage = Storage.storage().reference()
    
    public typealias UploadPictureCompletion = (Result<String, Error>) -> (Void)
    //MARK: Profile pic
    ///Uploads picture to Firebase Storage and returns completion with URL string to download
    public func uploadProfilePic(with data: Data, fileName: String, completion: @escaping  UploadPictureCompletion) {
        storage.child("images/\(fileName)").putData(data, metadata: nil, completion: { [weak self] metadata, error in
            guard error == nil else {
                print("Failed to upload data to firebase for picture in storage manager file")
                completion(.failure(StorageErrors.failedToUpload))
                return
            }
            self?.storage.child("images/\(fileName)").downloadURL(completion: { url, error in
                guard let url = url else {
                    print("Failed to get download url in storage manager")
                    completion(.failure(StorageErrors.failedToGetDownloadURL))
                    
                    return }
                let urlString = url.absoluteString
                print("download url returned: \(urlString)")
                completion(.success(urlString))
            })
            
        })
    }
    
    public func downloadURL(for path: String, completion: @escaping (Result<URL, Error>) -> Void) {
        let reference = storage.child(path)
        reference.downloadURL(completion: { url, error in
            guard let url = url, error == nil else {
                completion(.failure(StorageErrors.failedToGetDownloadURL))
                return }
            completion(.success(url))
        })
    }
    //MARK: Attaching pic in chat
    ///Uploads picture that will be sent as an attachment to Firebase Storage
    public func uploadMessagePhoto(with data: Data, fileName: String, completion: @escaping  UploadPictureCompletion) {
        storage.child("message_images/\(fileName)").putData(data, metadata: nil, completion: { [weak self] metadata, error in
            guard error == nil else {
                print("Failed to upload data to firebase for picture in storage manager file")
                completion(.failure(StorageErrors.failedToUpload))
                return
            }
            self?.storage.child("message_images/\(fileName)").downloadURL(completion: { url, error in
                guard let url = url else {
                    print("Failed to get download url in storage manager")
                    completion(.failure(StorageErrors.failedToGetDownloadURL))
                    
                    return }
                let urlString = url.absoluteString
                print("download url returned: \(urlString)")
                completion(.success(urlString))
            })
        })
    }
    ///Uploads video that will be sent as an attachment to Firebase Storage
    public func uploadMessageVideo(with fileUrl: URL, fileName: String, completion: @escaping  UploadPictureCompletion) {
        storage.child("message_videos/\(fileName)").putFile(from: fileUrl, metadata: nil, completion: { [weak self] metadata, error in
            guard error == nil else {
                print("Failed to upload video file to firebase")
                completion(.failure(StorageErrors.failedToUpload))
                return
            }
            self?.storage.child("message_videos/\(fileName)").downloadURL(completion: { url, error in
                guard let url = url else {
                    print("Failed to get download url in storage manager")
                    completion(.failure(StorageErrors.failedToGetDownloadURL))
                    
                    return }
                let urlString = url.absoluteString
                print("download url returned: \(urlString)")
                completion(.success(urlString))
            })
        })
    }
}


