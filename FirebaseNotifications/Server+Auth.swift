//
//  Server+Auth.swift
//  FirebaseNotifications
//
//  Created by Kelvin Lau on 2016-10-24.
//  Copyright © 2016 Kelvin Lau. All rights reserved.
//

import Firebase

// MARK: - Authentication
extension Server {
  enum AuthResponse {
    case success
    case failure(String)
  }
  
  static var auth: FIRAuth? {
    return FIRAuth.auth()
  }
  
  static var currentUserId: String? {
    return FIRAuth.auth()?.currentUser?.uid
  }
  
  static var currentUserEmail: String? {
    return FIRAuth.auth()?.currentUser?.email
  }
  
  static func createAccount(withEmail email: String, password: String, completion: @escaping (AuthResponse) -> ()) {
    guard let auth = Server.auth else { return completion(.failure("Couldn't even get \"FIRAuth.auth()\"! This is a Firebase problem. Better contact their developer support team.")) }
    auth.createUser(withEmail: email, password: password) { _, error in
      if let error = error {
        completion(.failure(error.localizedDescription))
      } else {
        completion(.success)
      }
    }
  }
  
  static func login(withEmail email: String, password: String, completion: @escaping (AuthResponse) -> ()) {
    guard let auth = Server.auth else { return completion(.failure("Couldn't even get \"FIRAuth.auth()\"! This is a Firebase problem. Better contact their developer support team.")) }
    auth.signIn(withEmail: email, password: password) { user, error in
      if let error = error {
        completion(.failure(error.localizedDescription))
      } else if let user = user {
        Server.registerForNotifications(forUID: user.uid)
        completion(.success)
      }
    }
  }
  
  static func logout(completion: @escaping (Bool) -> ()) {
    guard let auth = Server.auth else { return completion(false) }
    try? auth.signOut()
    completion(true)
  }
}
