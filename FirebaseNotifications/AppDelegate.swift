//
//  AppDelegate.swift
//  FirebaseNotifications
//
//  Created by Kelvin Lau on 2016-10-24.
//  Copyright © 2016 Kelvin Lau. All rights reserved.
//

import UIKit
import Firebase
import UserNotifications

@UIApplicationMain
final class AppDelegate: UIResponder {

  var window: UIWindow?
  
  override init() {
    super.init()
    FIRApp.configure()
  }
}

// MARK: - UIApplicationDelegate
extension AppDelegate: UIApplicationDelegate {
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
    let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
    UNUserNotificationCenter.current().requestAuthorization(options: authOptions, completionHandler: { _, _ in })
    
    UNUserNotificationCenter.current().delegate = self
    FIRMessaging.messaging().remoteMessageDelegate = self
    
    application.registerForRemoteNotifications()
    NotificationCenter.default.addObserver(self, selector: #selector(tokenRefreshNotification), name: .firInstanceIDTokenRefresh, object: nil)
    
    Server.configureBatch()
    
    return true
  }
  
  func tokenRefreshNotification(notification: Notification) {
    if let refreshedToken = FIRInstanceID.instanceID().token() {
      print("InstanceID token: \(refreshedToken)")
    }
    
    connectToFcm()
  }
  
  func connectToFcm() {
    FIRMessaging.messaging().connect { error in
      if let error = error {
        print("Unable to connect with FCM. \(error)")
      } else {
        print("Connected to FCM.")
      }
    }
  }
  
  func applicationDidBecomeActive(_ application: UIApplication) {
    connectToFcm()
  }
  
  func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    FIRInstanceID.instanceID().setAPNSToken(deviceToken, type: .sandbox)
//    let deviceTokenString = deviceToken.reduce("") { $0 + String(format: "%02X", $1) }
//    UserDefaults.standard.setValue(deviceTokenString, forKey: "deviceTokenString")
//    UserDefaults.standard.synchronize()
  }
}

// MARK: - UNUserNotificationCenterDelegate
extension AppDelegate: UNUserNotificationCenterDelegate {
  func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    print("UNUserNotificationCenterDelegate willPresent called!!!")
    completionHandler([.alert, .sound])
  }
}

// MARK: - FIRMessagingDelegate
extension AppDelegate: FIRMessagingDelegate {
  func applicationReceivedRemoteMessage(_ remoteMessage: FIRMessagingRemoteMessage) {
    print("FIRMessagingRemoteMessage Received: \(remoteMessage.appData)")
  }
}
