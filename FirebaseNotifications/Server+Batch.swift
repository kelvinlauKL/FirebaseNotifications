//
//  Server+Batch.swift
//  FirebaseNotifications
//
//  Created by Kelvin Lau on 2016-10-24.
//  Copyright © 2016 Kelvin Lau. All rights reserved.
//

import Batch

extension Server {
  static var batchDevApiKey: String {
    return "DEV580DDBECC5CAE32A22B137B16D6"
  }
  
  static var batchRestApiKey: String {
    return "4a6e150cd3fbe6fd08bf24d5010bf1ed"
  }
  
  static var batchInstallationID: String? {
    return BatchUser.installationID()
  }
  
  static func configureBatch() {
    Batch.start(withAPIKey: "DEV580DDBECC5CAE32A22B137B16D6")
    BatchPush.registerForRemoteNotifications()
  }
  
  static func registerForNotifications(forUID uid: String) {
    let editor = BatchUser.editor()
    editor.setIdentifier(uid)
    editor.save()
  }
  
  static func sendNotification(toUserWithID uid: String) {
    guard let pushClient = BatchClientPush(apiKey: Server.batchDevApiKey, restKey: Server.batchRestApiKey) else { return print("Error while initializing BatchClientPush") }
    pushClient.sandbox = true
    pushClient.customPayload = ["aps": ["badge": 7]]
    pushClient.groupId = "tests"
    pushClient.message.title = "iOS Push"
    pushClient.message.body = "Batch's working!"
    pushClient.recipients.customIds = ["foo"]
    pushClient.recipients.tokens.append("3e36d39747f839b58e39cd56c9fbb76c6a081969362ad0a44eb5bbad313aa819")
    
    pushClient.send { response, error in
      if let error = error {
        print("Something happened while sending the push: \(response) \(error.localizedDescription)")
      } else {
        print("Push sent \(response)")
      }
    }
  }
}

final class BatchClientPush: NSObject, URLSessionDelegate {
  private static let apiURLFormat = "https://api.batch.com/1.0/%@/transactional/send"
  private static let apiMaxRecipients = 10000
  private static let jsonContentType = "application/json"
  
  fileprivate let apiKey: String
  fileprivate let restKey: String
  
  private let session = URLSession(configuration: .default)

  private(set) var message = BatchClientPushMessage()
  private(set) var recipients = BatchClientPushRecipients()
  var sandbox = false
  var customPayload: [String: Any]? = nil
  var groupId = "ios_push"
  var deeplink: String? = nil
  
  init?(apiKey: String, restKey: String) {
    guard apiKey.characters.count == 30 && restKey.characters.count == 32 else { return nil }
    self.apiKey = apiKey
    self.restKey = restKey
  }
  
  func send(completionHandler: @escaping (_ response: String?, _ error: NSError?) -> ()) {
    guard recipients.count > 0 else {
      completionHandler(nil, NSError(domain: "BatchClientPushErrorDomain",
                                     code: -2,
                                     userInfo: [NSLocalizedDescriptionKey: "Validation error: No recipients were specified"]))
      return
    }
    
    guard recipients.count <= BatchClientPush.apiMaxRecipients else {
      completionHandler(nil, NSError(domain: "BatchClientPushErrorDomain",
                                     code: -2,
                                     userInfo: [NSLocalizedDescriptionKey: "Validation error: Recipients count exceeds \(BatchClientPush.apiMaxRecipients)"]))
      return
    }
    
    var jsonPayload: Data?
    
    if let customPayload = customPayload {
      do {
        jsonPayload = try JSONSerialization.data(withJSONObject: customPayload, options: [])
      } catch let error as NSError {
        completionHandler(nil, NSError(domain: "BatchClientPushErrorDomain",
                                       code: -3,
                                       userInfo: [
                                        NSUnderlyingErrorKey: error,
                                        NSLocalizedDescriptionKey: "Validation error: An error occurred while serializing the custom payload to JSON. Make sure it's a dictionary only made of foundation objects compatible with NSJSONSerialization. (Additional info: \(error.localizedDescription)"
          ]))
        return
      }
    }
    
    guard let request = buildRequest(customPayload: jsonPayload) else {
      completionHandler(nil, NSError(domain: "BatchClientPushErrorDomain",
                                     code: -1,
                                     userInfo: [NSLocalizedDescriptionKey: "Unknown error while building the HTTP request"]))
      return
    }
    
    let task = session.dataTask(with: request, completionHandler: {
      (data: Data?, response: URLResponse?, error: Error?) in
      
      var stringResponseData: String?
      if let data = data {
        stringResponseData = String(data: data, encoding: String.Encoding.utf8)
      }
      
      var userFacingError = error as? NSError
      
      if let response = response as? HTTPURLResponse
        , response.statusCode != 201 && error == nil {
        userFacingError = NSError(domain: "BatchClientPushErrorDomain",
                                  code: -4,
                                  userInfo: [
                                    NSLocalizedDescriptionKey: "Server error: Status code \(response.statusCode), please see the response string for more info."
          ])
      }
      
      completionHandler(stringResponseData, userFacingError)
    })
    
    task.resume()
  }
  
  private func buildRequest(customPayload: Data?) -> URLRequest? {
    guard let url = URL(string: String(format: BatchClientPush.apiURLFormat, apiKey)) else { return nil }
    
    guard let body = buildRequestBody(customPayload: customPayload) else { return nil }
    
    var request = URLRequest(url: url)
    
    request.httpMethod = "POST"
    request.httpBody = body
    request.setValue(restKey, forHTTPHeaderField: "X-Authorization")
    request.setValue(BatchClientPush.jsonContentType, forHTTPHeaderField: "Accept")
    request.setValue(BatchClientPush.jsonContentType, forHTTPHeaderField: "Content-Type")
    
    return request
  }
  
  private func buildRequestBody(customPayload: Data?) -> Data? {
    var body: [String: Any] = [:]
    body["group_id"] = groupId
    body["sandbox"] = sandbox
    body["recipients"] = [
      "custom_ids": recipients.customIds,
      "tokens": recipients.tokens,
      "install_ids": recipients.installIds
    ]
    
    body["message"] = message.dictionaryRepresentation
    
    if let customPayload = customPayload {
      body["custom_payload"] = String(data: customPayload, encoding: String.Encoding.utf8)
    }
    
    if let deeplink = deeplink {
      body["deeplink"] = deeplink
    }
    
    do {
      return try JSONSerialization.data(withJSONObject: body, options: [])
    } catch {
      return nil
    }
  }
  
  class BatchClientPushMessage {
    var title: String?
    var body: String = ""
    
    var dictionaryRepresentation: [String: Any] {
      var res = ["body": body]
      if let title = title {
        res["title"] = title
      }
      
      return res
    }
  }
  
  class BatchClientPushRecipients {
    var customIds: [String] = []
    var installIds: [String] = []
    var tokens: [String] = []
    
    var count: Int {
      return customIds.count + installIds.count + tokens.count
    }
  }
}

