//
//  LoginViewController.swift
//  FirebaseNotifications
//
//  Created by Kelvin Lau on 2016-10-24.
//  Copyright © 2016 Kelvin Lau. All rights reserved.
//

import UIKit

final class LoginViewController: UIViewController {
  @IBOutlet fileprivate var emailTextField: UITextField!
  @IBOutlet fileprivate var passwordTextField: UITextField!
}

// MARK: - SegueHandlerType
extension LoginViewController: SegueHandlerType {
  enum SegueIdentifier: String {
    case showDetails
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    switch segueIdentifierFor(segue: segue) {
    case .showDetails:
      break
    }
  }
}

// MARK: - @IBActions
private extension LoginViewController {
  @IBAction func loginButtonTapped() {
    guard let email = emailTextField.text, let password = passwordTextField.text else { fatalError() }
    Server.login(withEmail: email, password: password) { authResponse in
      switch authResponse {
      case .success:
        self.performSegue(withIdentifier: .showDetails, sender: nil)
      case let .failure(message):
        print("failed to log in: \(message)")
      }
    }
  }
  
  @IBAction func createAccountButtonTapped() {
    guard let email = emailTextField.text, let password = passwordTextField.text else { fatalError() }
    Server.createAccount(withEmail: email, password: password) { authResponse in
      switch authResponse {
      case .success:
        print("successfully created account!")
      case let .failure(message):
        print("failed to create account: \(message)")
      }
    }
  }
}
