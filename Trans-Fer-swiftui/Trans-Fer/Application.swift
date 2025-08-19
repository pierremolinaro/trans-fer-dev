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
    WindowGroup {
      StartUpView ()
    }
    Settings {
      PreferencesView ().navigationTitle("Préférences").frame (width: 600)
    }
    DocumentGroup (newDocument: Document_TransfertPIC ()) { configuration in
      Document_TransfertPIC_View (
        document: configuration.$document,
        fileURL: configuration.fileURL
      )
    }
  }

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

}

//--------------------------------------------------------------------------------------------------
