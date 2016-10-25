//
//  LoginDetailsViewController.swift
//  FirebaseNotifications
//
//  Created by Kelvin Lau on 2016-10-24.
//  Copyright © 2016 Kelvin Lau. All rights reserved.
//

import UIKit

final class LoginDetailsViewController: UIViewController {
  @IBOutlet private var usernameLabel: UILabel! { didSet {
    usernameLabel.text = "Email: \(Server.currentUserEmail!)"
  }}
  
  @IBOutlet private var userIdLabel: UILabel! { didSet {
    userIdLabel.text = "UserID: \(Server.currentUserId!)"
  }}
  
  @IBOutlet private var batchLabel: UILabel! { didSet {
    batchLabel.text = "BatchID: \(Server.batchInstallationID!)"
  }}
}

// MARK: - @IBActionss
private extension LoginDetailsViewController {
  @IBAction func sendNotificationTapped() {
    Server.sendNotification(toUserWithID: "")
  }
  
  @IBAction func logoutTapped() {
    Server.logout { success in
      if success {
        self.dismiss(animated: true, completion: nil)
      }
    }
  }
}
