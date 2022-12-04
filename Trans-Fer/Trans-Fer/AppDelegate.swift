//
//  AppDelegate.swift
//  FlashagePic
//
//  Created by Pierre Molinaro on 09/02/2022.
//
//——————————————————————————————————————————————————————————————————————————————————————————————————

import AppKit
import Sparkle

//——————————————————————————————————————————————————————————————————————————————————————————————————

let PREFS_PICCOLO_APP = "piccoloApplicationPath"
let PREFS_ARDUINO_APP = "arduinoApplicationPath"
let PREFS_ADRESSE_IP_CARTE_MEZZANINE = "adresseIPCarteMezzanine"

//——————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

fileprivate let SU_LAST_CHECK_TIME = "SULastCheckTime"

//——————————————————————————————————————————————————————————————————————————————————————————————————

var gAppDelegate : AppDelegate? = nil

//——————————————————————————————————————————————————————————————————————————————————————————————————

@main class AppDelegate : NSObject, NSApplicationDelegate {

  //································································································

  @IBOutlet var mCocoaPiccoloApplicationPathButton : NSButton? = nil
  @IBOutlet var mCocoaArduinoApplicationPathButton : NSButton? = nil
  @IBOutlet var mAdresseIPCarteMezzanineTextField : NSTextField? = nil
  @IBOutlet var mLogWindow : NSWindow? = nil
  @IBOutlet var mLogTextView : NSTextView? = nil

  //································································································

  override init () {
    super.init ()
    gAppDelegate = self
  }

  //································································································

  func applicationDidFinishLaunching (_ aNotification : Notification) {
    if UserDefaults.standard.string (forKey: PREFS_PICCOLO_APP) == nil {
      UserDefaults.standard.set ("/Applications/CocoaPiccolo.app", forKey: PREFS_PICCOLO_APP)
    }
    if UserDefaults.standard.string (forKey: PREFS_ARDUINO_APP) == nil {
      UserDefaults.standard.set ("/Applications/Arduino.app", forKey: PREFS_ARDUINO_APP)
    }
    if UserDefaults.standard.string (forKey: PREFS_ADRESSE_IP_CARTE_MEZZANINE) == nil {
      UserDefaults.standard.set ("192.168.1.68", forKey: PREFS_ADRESSE_IP_CARTE_MEZZANINE)
    }
    self.mAdresseIPCarteMezzanineTextField?.bind (
      .value,
      to: UserDefaults.standard,
      withKeyPath: PREFS_ADRESSE_IP_CARTE_MEZZANINE,
      options: [NSBindingOption.continuouslyUpdatesValue : true]
    )
    self.mCocoaPiccoloApplicationPathButton?.bind (
      .title,
      to: UserDefaults.standard,
      withKeyPath: PREFS_PICCOLO_APP,
      options: nil
    )
    self.mCocoaArduinoApplicationPathButton?.bind (
      .title,
      to: UserDefaults.standard,
      withKeyPath: PREFS_ARDUINO_APP,
      options: nil
    )
    self.mCocoaPiccoloApplicationPathButton?.target = self
    self.mCocoaPiccoloApplicationPathButton?.action = #selector (Self.selectPiccoloApplication (_:))
    self.mCocoaArduinoApplicationPathButton?.target = self
    self.mCocoaArduinoApplicationPathButton?.action = #selector (Self.selectArduinoApplication (_:))
  }

  //································································································

  @objc func selectPiccoloApplication (_ inSender : NSButton) {
    if let window = inSender.window {
      let op = NSOpenPanel ()
      op.allowsMultipleSelection = false
      op.canChooseDirectories = true
      op.canChooseFiles = true
      op.beginSheetModal (for: window) { (_ response : NSApplication.ModalResponse) in
        op.orderOut (nil)
        if response == .OK, let path = op.url?.path {
          // Swift.print ("\(path)")
          UserDefaults.standard.set (path, forKey: PREFS_PICCOLO_APP)
        }
      }
    }
  }

  //································································································

  @objc func selectArduinoApplication (_ inSender : NSButton) {
    if let window = inSender.window {
      let op = NSOpenPanel ()
      op.allowsMultipleSelection = false
      op.canChooseDirectories = true
      op.canChooseFiles = true
      op.beginSheetModal (for: window) { (_ response : NSApplication.ModalResponse) in
        op.orderOut (nil)
        if response == .OK, let path = op.url?.path {
          // Swift.print ("\(path)")
          UserDefaults.standard.set (path, forKey: PREFS_ARDUINO_APP)
        }
      }
    }
  }

  //····················································································································
  //  DO NOT OPEN A NEW DOCUMENT ON LAUNCH
  //····················································································································

  func applicationShouldOpenUntitledFile (_ application : NSApplication) -> Bool {
    return false
  }

  //····················································································································
  //   Sparkle 2.x
  //····················································································································

  fileprivate let mUpdaterController = Sparkle.SPUStandardUpdaterController (updaterDelegate: nil, userDriverDelegate: nil)
//  @IBOutlet var mCheckNowForUpdateMenuItem : NSMenuItem? = nil
  @IBOutlet var mUsingSparkleTextField : NSTextField? = nil
  @IBOutlet var mSparkleLastCheckTimeTextField : NSTextField? = nil
  @IBOutlet var mAutomaticallyCheckForUpdateCheckBox : NSButton? = nil
  @IBOutlet var mUpdateCheckIntervalPopUpButton : NSPopUpButton? = nil

  //····················································································································

  override func awakeFromNib () {
//    self.mCheckNowForUpdateMenuItem?.target = self
//    self.mCheckNowForUpdateMenuItem?.action = #selector (Self.checkForUpdatesAction (_:))
    self.mUsingSparkleTextField?.stringValue = "Avec Sparkle " + self.sparkleVersionString ()
    self.mAutomaticallyCheckForUpdateCheckBox?.bind (
      NSBindingName.value,
      to: self.mUpdaterController.updater,
      withKeyPath: "automaticallyChecksForUpdates",
      options: nil
    )
    self.mUpdateCheckIntervalPopUpButton?.bind (
      NSBindingName.selectedTag,
      to: self.mUpdaterController.updater,
      withKeyPath: "updateCheckInterval",
      options: nil
    )
    self.mUpdateCheckIntervalPopUpButton?.bind (
      NSBindingName.enabled,
      to: self.mUpdaterController.updater,
      withKeyPath: "automaticallyChecksForUpdates",
      options: nil
    )
    let formatter = DateFormatter ()
    formatter.dateStyle = .long
    formatter.timeStyle = .short
    formatter.locale = Locale (identifier: "fr_FR")
    self.mSparkleLastCheckTimeTextField?.formatter = formatter
    self.mSparkleLastCheckTimeTextField?.bind (
      NSBindingName.value,
      to: UserDefaults.standard,
      withKeyPath: SU_LAST_CHECK_TIME,
      options: nil
    )

  }

  //····················································································································

  @IBAction func checkForUpdatesAction (_ inUnusedSender : Any?) {
    self.mUpdaterController.updater.checkForUpdates ()
  }

  //····················································································································

  func sparkleVersionString () -> String {
    var result = "?"
    if let frameworkURL = Bundle.main.privateFrameworksURL {
      let infoPlistURL = frameworkURL.appendingPathComponent ("Sparkle.framework/Versions/Current/Resources/Info.plist")
      if let data : Data = try? Data (contentsOf: infoPlistURL),
         let plist = try? PropertyListSerialization.propertyList (from: data, format: nil) as? NSDictionary,
         let sparkleVersionString = plist ["CFBundleShortVersionString"] as? String {
            result = sparkleVersionString
      }
    }
    return result
  }

  //····················································································································

  func configureAutomaticallyCheckForUpdatesButton (_ inOutlet : NSButton) {
    inOutlet.bind (
      NSBindingName.value,
      to: self.mUpdaterController.updater,
      withKeyPath: "automaticallyChecksForUpdates",
      options: nil
    )
  }

 //····················································································································

  func configureCheckIntervalPopUpButton (_ inOutlet : NSPopUpButton) {
    let updater = self.mUpdaterController.updater
    inOutlet.bind (
      NSBindingName.selectedTag,
      to: updater,
      withKeyPath: "updateCheckInterval",
      options: nil
    )
    inOutlet.bind (
      NSBindingName.enabled,
      to: updater,
      withKeyPath: "automaticallyChecksForUpdates",
      options: nil
    )
  }

  //································································································

}

//——————————————————————————————————————————————————————————————————————————————————————————————————
