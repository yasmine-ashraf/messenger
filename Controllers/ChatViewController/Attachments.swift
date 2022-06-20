//
//  Attachments.swift
//  Messenger
//
//  Created by Yasmine Ashraf on 25/08/2021.
//

import UIKit
import MessageKit
import MapKit
import InputBarAccessoryView
import SDWebImage
import AVKit
import CoreLocation

extension ChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    //delegate funcs:
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        spinner.startAnimating()
        guard let sender = sender,
              let messageId = generateMessageID(),
              let conversationId = conversationId,
              let name = self.title else {
            return
        }
        if let image = info[.editedImage] as? UIImage, let imageData = image.pngData() {
            let fileName = "photo_messsage_" + messageId.replacingOccurrences(of: " ", with: "-") + ".png"
            //Upload image and send message:
            StorageManager.shared.uploadMessagePhoto(with: imageData, fileName: fileName, completion: { [weak self] result in
                guard let strongSelf = self else {
                    return }
                switch result
                {
                case .success(let urlString):
                    print("uploaded message photo: \(urlString)")
                    guard let url = URL(string: urlString), let placeholder = UIImage(systemName: "plus") else {
                        return
                    }
                    let media = Media(url: url, image: nil, placeholderImage: placeholder, size: .zero)
                    let message = Message(sender: sender, messageId: messageId, sentDate: Date(), kind: .photo(media))
                    DatabaseManager.shared.sendMessage(to: conversationId, otherUserEmail: strongSelf.otherUserEmail, name: name, newMessage: message, completion: { success in
                        if success {
                            print("sent photo message")
                        }
                        else {
                            print("failed to send photo message")
                        }
                    })
                    break
                case .failure(let error):
                    print("error uploading attachment image to firebase storage: \(error)")
                }
            })
        }
        //else it's a video
        else if let videoUrl = info[.mediaURL] as? URL {
            let fileName = "video_messsage_" + messageId.replacingOccurrences(of: " ", with: "-") + ".mov"
            var targetURL = videoUrl
            if isGallery {
//FILEMANAGER:
                let urlString = videoUrl.relativeString
                let urlSlices = urlString.split(separator: ".")
                //Create a temp directory using the file name
                let tempDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
                targetURL = tempDirectoryURL.appendingPathComponent(String(urlSlices[1])).appendingPathExtension(String(urlSlices[2]))
                //Copy the video over
                try? FileManager.default.copyItem(at: videoUrl, to: targetURL)
            }
            //Upload video and send message:
            StorageManager.shared.uploadMessageVideo(with: targetURL, fileName: fileName, completion: { [weak self] result in
                guard let strongSelf = self else {
                    return }
                switch result
                {
                case .success(let urlString):
                    print("uploaded message video: \(urlString)")
                    guard let url = URL(string: urlString), let placeholder = UIImage(systemName: "plus") else {
                        return
                    }
                    let media = Media(url: url, image: nil, placeholderImage: placeholder, size: .zero)
                    let message = Message(sender: sender, messageId: messageId, sentDate: Date(), kind: .video(media))
                    DatabaseManager.shared.sendMessage(to: conversationId, otherUserEmail: strongSelf.otherUserEmail, name: name, newMessage: message, completion: { success in
                        if success {
                            print("sent video message")
                        }
                        else {
                            print("failed to send video message")
                        }
                    })
                    break
                case .failure(let error):
                    print("error uploading attachment video to firebase storage: \(error)")
                }
            })
        }

        spinner.stopAnimating()
    }
    func setupInputButton () {
        let button = InputBarButtonItem()
        button.setSize(CGSize(width: 35, height: 35), animated: false)
        button.setImage(UIImage(systemName: "paperclip"), for: .normal)
        button.onTouchUpInside({ [weak self] _ in
            self?.presentInputActionSheet()
        })
        messageInputBar.setLeftStackViewWidthConstant(to: 36, animated: false)
        messageInputBar.setStackViewItems([button], forStack: .left, animated: false)
        
    }
    func presentInputActionSheet() {
        let actionSheet = UIAlertController(title: "Attach Media", message: "What would you like to attach?", preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Photo", style: .default, handler: { [weak self] _ in
            self?.presentPhotoInputActionSheet()
        }))
        actionSheet.addAction(UIAlertAction(title: "Video", style: .default, handler: { [weak self] _ in
            self?.presentVideoInputActionSheet()
        }))
//        actionSheet.addAction(UIAlertAction(title: "Audio", style: .default, handler: { [weak self] _ in
//
//        }))
        actionSheet.addAction(UIAlertAction(title: "Location", style: .default, handler: { [weak self] _ in
            self?.presentLocationPicker()
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(actionSheet, animated:  true)
    }
    func presentPhotoInputActionSheet() {
        let actionSheet = UIAlertController(title: "Attach Photo", message: "Where would you like to attach a photo from?", preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: { [weak self] _ in
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.delegate = self
            picker.allowsEditing = true
            self?.present(picker, animated: true)
        }))
        actionSheet.addAction(UIAlertAction(title: "Photo Library", style: .default, handler: { [weak self] _ in
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.delegate = self
            picker.allowsEditing = true
            self?.present(picker, animated: true)
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(actionSheet, animated:  true)
    }
    func presentVideoInputActionSheet() {
        let actionSheet = UIAlertController(title: "Attach Video", message: "Where would you like to attach a video from?", preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: { [weak self] _ in
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.delegate = self
            picker.mediaTypes = ["public.movie"]
            self?.isGallery = false
            picker.videoQuality = .typeMedium
            picker.allowsEditing = true
            self?.present(picker, animated: true)
        }))
        actionSheet.addAction(UIAlertAction(title: "Photo Library", style: .default, handler: { [weak self] _ in
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.delegate = self
            self?.isGallery = true
            picker.mediaTypes = ["public.movie"]
            picker.videoQuality = .typeMedium
            picker.allowsEditing = true
            self?.present(picker, animated: true)
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(actionSheet, animated:  true)
    }
    func presentLocationPicker() {
        let vc = LocationPickerViewController(coordinates: nil)
        vc.title = "Pick Location"
        vc.navigationItem.largeTitleDisplayMode = .never
        vc.completion = { [weak self] selectedCoordinates in
            guard let strongSelf = self else {
                return
            }
            let long:Double = selectedCoordinates.longitude
            let lat: Double = selectedCoordinates.latitude
            print("Longitude: \(long), Latitude: \(lat)")
            guard let sender = strongSelf.sender,
                  let messageId = strongSelf.generateMessageID(),
                  let conversationId = strongSelf.conversationId,
                  let name = strongSelf.title else {
                return
            }
            let location = Location(location: CLLocation(latitude: lat, longitude: long), size: .zero)
            let message = Message(sender: sender, messageId: messageId, sentDate: Date(), kind: .location(location))
            DatabaseManager.shared.sendMessage(to: conversationId, otherUserEmail: strongSelf.otherUserEmail, name: name, newMessage: message, completion: { success in
                if success {
                    print("sent location message")
                }
                else {
                    print("failed to send location message")
                }
            })
        }
        navigationController?.pushViewController(vc, animated: true)
    }
}
