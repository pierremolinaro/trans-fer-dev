//
//  SparkleSwiftUI.swift
//  Trans-Fer
//
//  Created by Pierre Molinaro on 16/08/2025.
//
//--------------------------------------------------------------------------------------------------

import SwiftUI
import Combine
import Sparkle

//--------------------------------------------------------------------------------------------------
// https://medium.com/@borto_ale/integrating-sparkle-updater-in-swiftui-for-macos-82ae4e0b4ac6
//--------------------------------------------------------------------------------------------------
//Add the following to your app’s Info.plist:
//
//<key>SUEnableInstallerLauncherService</key>
//<true/>
//
//<key>SUEnableDownloaderService</key>
//<true/>
//
//<key>SUFeedURL</key>
//<string>https://your_github_username.github.io./your_repository_name/appcast.xml</string>
//
//<key>SUPublicEDKey</key>
//<string>your_previous_generated_public_Key</string>
//
//--------------------------------------------------------------------------------------------------
// Add keys to your app’s entitlements file:
//
//<key>com.apple.security.temporary-exception.mach-lookup.global-name</key>
//<array>
//    <string>$(PRODUCT_BUNDLE_IDENTIFIER)-spks</string>
//    <string>$(PRODUCT_BUNDLE_IDENTIFIER)-spki</string>
//</array>
//
//--------------------------------------------------------------------------------------------------

struct SparkleView : View {

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  var body: some View {
    VStack {
      HStack {
        Button ("Rechercher les mises à jour de l'application…") {
          self.mUpdaterController.checkForUpdates (nil)
        }
        Text ("Avec Sparkle " + self.sparkleVersionString ())
        Spacer ()
      }
      HStack {
        Toggle ("Rechercher les mises à jour automatiquement", isOn: self.$mAutomaticallyChecksForUpdates)
        .layoutPriority (1)
        Picker("", selection: self.$mCheckIntervalInSeconds) {
          Text("Chaque jour").tag (3600 * 24)
          Text("Chaque semaine").tag (3600 * 24 * 7)
          Text("Chaque mois").tag (3600 * 24 * 30)
        }.labelsHidden ()
      }
      HStack {
        Text ("Dernière recherche ")
        Text (self.lastUpdateCheckDateString ())
        Spacer ()
      }
    }
    .onChange (of: self.mAutomaticallyChecksForUpdates) { (oldValue, newValue) in
      self.mUpdaterController.updater.willChangeValue (for: \.automaticallyChecksForUpdates)
      self.mUpdaterController.updater.automaticallyChecksForUpdates = self.mAutomaticallyChecksForUpdates
      self.mUpdaterController.updater.didChangeValue (for: \.automaticallyChecksForUpdates)
    }
    .onChange (of: self.mCheckIntervalInSeconds) { (oldValue, newValue) in
      self.mUpdaterController.updater.willChangeValue (for: \.updateCheckInterval)
      self.mUpdaterController.updater.updateCheckInterval = Double (self.mCheckIntervalInSeconds)
      self.mUpdaterController.updater.didChangeValue (for: \.updateCheckInterval)
    }
  }

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  //   Sparkle 2.x
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  private let mUpdaterController = Sparkle.SPUStandardUpdaterController (updaterDelegate: nil, userDriverDelegate: nil)
  @State private var mAutomaticallyChecksForUpdates : Bool
  @State private var mCheckIntervalInSeconds : Int
  @ObservedObject var mLastUpdateCheckDate = OptionalDateAppStorage ("SULastCheckTime")

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  init () {
    self.mAutomaticallyChecksForUpdates = self.mUpdaterController.updater.automaticallyChecksForUpdates
    self.mCheckIntervalInSeconds = Int (self.mUpdaterController.updater.updateCheckInterval)
  }

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

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

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  func lastUpdateCheckDateString () -> String {
    if let date = self.mLastUpdateCheckDate.date {
      let formatter = DateFormatter ()
      formatter.dateStyle = .long
      formatter.timeStyle = .short
      formatter.locale = Locale (identifier: "fr_FR")
      return formatter.string (from: date)
    }else{
      return ""
    }
  }

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

}

//--------------------------------------------------------------------------------------------------
