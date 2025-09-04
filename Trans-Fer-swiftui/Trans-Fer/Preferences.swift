//
//  Preferences.swift
//  Trans-Fer
//
//  Created by Pierre Molinaro on 16/08/2025.
//
//--------------------------------------------------------------------------------------------------

import SwiftUI
import UniformTypeIdentifiers

//--------------------------------------------------------------------------------------------------
// https://medium.com/@borto_ale/integrating-sparkle-updater-in-swiftui-for-macos-82ae4e0b4ac6

let PREFS_PICCOLO_APP = "piccoloApplicationPath"
let PREFS_ARDUINO_CLI_TOOL = "arduinoCliTool"
let PREFS_ADRESSE_IP_CARTE_MEZZANINE = "adresseIPCarteMezzanine"

//--------------------------------------------------------------------------------------------------

struct PreferencesView : View {

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  @AppStorage(PREFS_PICCOLO_APP) private var mPiccoloAppPath = "/Applications/CocoaPiccolo.app"
  @AppStorage(PREFS_ARDUINO_CLI_TOOL) private var mArduinoCLIPath = "/opt/homebrew/bin/arduino-cli"
  @AppStorage(PREFS_ADRESSE_IP_CARTE_MEZZANINE) private var mMezzanineIP = "192.168.1.68"
  @State private var mIsPresentingPiccoloAppFileImporter = false

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  var body: some View {
    VStack (spacing: 12) {
      HStack {
        Text ("Chemin de l'application Piccolo")
        Spacer ()
      }
      Button (action: { self.mIsPresentingPiccoloAppFileImporter = true }) {
        Text (self.mPiccoloAppPath).frame (maxWidth: .infinity)
      }.help (self.mPiccoloAppPath)
      Divider ()
      HStack {
        Text ("Chemin du compilateur Arduino en ligne de commande")
        Spacer ()
      }
      TextField ("", text: self.$mArduinoCLIPath).frame (maxWidth: .infinity)
      Divider ()
      HStack {
        Text ("Adresse IP gestionnaire central")
        TextField ("", text: self.$mMezzanineIP).frame (maxWidth: .infinity)
      }
      Divider ()
    //--- Sparkle
      SparkleView ()
    }.padding (12)
    .fileImporter (
      isPresented: self.$mIsPresentingPiccoloAppFileImporter,
      allowedContentTypes: [.applicationBundle],
      onCompletion: { self.definirCheminApplicationPiccolo (result: $0) }
    ).fileDialogDefaultDirectory (self.piccoloAppFileImporterDefaultDirectory ())
  }

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  func piccoloAppFileImporterDefaultDirectory () -> URL? {
    if let path = UserDefaults.standard.string (forKey: PREFS_PICCOLO_APP) {
      let directoryURL = URL (fileURLWithPath: path).deletingLastPathComponent ()
      if directoryURL.hasDirectoryPath {
        return directoryURL
      }
    }
    return nil
  }

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  private func definirCheminApplicationPiccolo (result inResult : Result<URL, any Error>) {
    switch inResult {
    case .success (let url) :
      UserDefaults.standard.set (url.path, forKey: PREFS_PICCOLO_APP)
    case .failure (let error):
      print (error)
    }
  }

//  func definirCheminApplicationPiccolo (result inResult : Result<URL, Error>) {
//    if let window = inWindow {
//      let op = NSOpenPanel ()
//      if let path = UserDefaults.standard.string (forKey: PREFS_PICCOLO_APP) {
//        let directoryURL = URL (fileURLWithPath: path).deletingLastPathComponent ()
//        if directoryURL.hasDirectoryPath {
//          op.directoryURL = directoryURL
//        }
//      }
//      op.isExtensionHidden = false
//      op.allowedContentTypes = [.applicationBundle]
//      op.allowsMultipleSelection = false
//      op.canChooseDirectories = false
//      op.canChooseFiles = true
//      op.beginSheetModal (for: window) { (_ inResponse : NSApplication.ModalResponse) in
//        DispatchQueue.main.async {
//          op.orderOut (nil)
//          if inResponse == .OK, let path = op.url?.path {
//            UserDefaults.standard.set (path, forKey: PREFS_PICCOLO_APP)
//          }
//        }
//      }
//    }
//  }

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

}

//--------------------------------------------------------------------------------------------------
