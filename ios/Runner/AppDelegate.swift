import Flutter
import BackgroundTasks
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    AppIconScheduler.registerBackgroundTask()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}

enum AppIconScheduler {
  private static let taskIdentifier = "com.example.medizinischerAiBot.sad-icon-refresh"
  private static let lastOpenedKey = "medi.app_icon.last_opened"
  private static let sadIconName = "MediSad"
  private static let inactiveInterval: TimeInterval = 7 * 24 * 60 * 60

  static func registerBackgroundTask() {
    BGTaskScheduler.shared.register(
      forTaskWithIdentifier: taskIdentifier,
      using: nil
    ) { task in
      guard let refreshTask = task as? BGAppRefreshTask else {
        task.setTaskCompleted(success: false)
        return
      }
      updateIconIfInactive(refreshTask)
    }
  }

  static func appWillEnterForeground() {
    UserDefaults.standard.set(Date(), forKey: lastOpenedKey)
    setIcon(nil)
    scheduleBackgroundRefresh()
  }

  private static func scheduleBackgroundRefresh() {
    let lastOpened = UserDefaults.standard.object(forKey: lastOpenedKey) as? Date ?? Date()
    let request = BGAppRefreshTaskRequest(identifier: taskIdentifier)
    request.earliestBeginDate = max(
      Date(),
      lastOpened.addingTimeInterval(inactiveInterval)
    )

    do {
      try BGTaskScheduler.shared.submit(request)
    } catch {
      NSLog("Medi app icon refresh could not be scheduled: %@", error.localizedDescription)
    }
  }

  private static func updateIconIfInactive(_ task: BGAppRefreshTask) {
    task.expirationHandler = {
      task.setTaskCompleted(success: false)
    }

    guard let lastOpened = UserDefaults.standard.object(forKey: lastOpenedKey) as? Date,
          Date().timeIntervalSince(lastOpened) >= inactiveInterval else {
      scheduleBackgroundRefresh()
      task.setTaskCompleted(success: true)
      return
    }

    guard UIApplication.shared.supportsAlternateIcons else {
      task.setTaskCompleted(success: false)
      return
    }

    DispatchQueue.main.async {
      UIApplication.shared.setAlternateIconName(sadIconName) { error in
        if let error {
          NSLog("Medi sad app icon could not be set: %@", error.localizedDescription)
        }
        task.setTaskCompleted(success: error == nil)
      }
    }
  }

  private static func setIcon(_ name: String?) {
    guard UIApplication.shared.supportsAlternateIcons,
          UIApplication.shared.alternateIconName != name else {
      return
    }
    UIApplication.shared.setAlternateIconName(name) { error in
      if let error {
        NSLog("Medi app icon could not be restored: %@", error.localizedDescription)
      }
    }
  }
}
