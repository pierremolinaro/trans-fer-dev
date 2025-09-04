//
//  Trans_FerApp.swift
//  Trans-Fer
//
//  Created by Pierre Molinaro on 16/08/2025.
//
//--------------------------------------------------------------------------------------------------

import SwiftUI

//--------------------------------------------------------------------------------------------------

@main struct Application : App {

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  var body : some Scene {
//    WindowGroup {
//      StartUpView ()
//    }
    DocumentGroup (newDocument: TransfertPIC_Document ()) { configuration in
      TransfertPIC_DocumentView (
        document: configuration.$document,
        fileURL: configuration.fileURL
      )
    }
    Settings {
      PreferencesView ().navigationTitle("Préférences").frame (width: 600)
    }
  }

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

}

//--------------------------------------------------------------------------------------------------
