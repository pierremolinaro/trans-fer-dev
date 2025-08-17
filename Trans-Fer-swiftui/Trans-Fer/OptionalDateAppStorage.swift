//
//  OptionalDateAppStorage.swift
//  date-optionnelle-dans-preferences
//
//  Created by Pierre Molinaro on 16/08/2025.
//
//--------------------------------------------------------------------------------------------------

import SwiftUI
import Combine

//--------------------------------------------------------------------------------------------------

final class OptionalDateAppStorage : ObservableObject {

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  private let mKey : String

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  @Published var date : Date? {
    willSet {
      if newValue != self.date {
        UserDefaults.standard.set (newValue, forKey: self.mKey)
      }
    }
  }

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  init (_ inKey : String) {
    self.mKey = inKey
    self.date = UserDefaults.standard.object (forKey: inKey) as? Date
  //--- Add observer
    NotificationCenter.default.addObserver (
      self,
      selector: #selector (Self.userDefaultDidChange (_:)),
      name: UserDefaults.didChangeNotification,
      object: nil
    )
  }

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  // Remove observer
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  @MainActor deinit {
    NotificationCenter.default.removeObserver (
      self,
      name: UserDefaults.didChangeNotification,
      object: nil
    )
  }

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  @objc private func userDefaultDidChange (_ inUnusedNotification : Notification) {
    let d : Date? = UserDefaults.standard.object (forKey: self.mKey) as? Date
    if self.date != d {
      DispatchQueue.main.async {
        self.date = d
      }
    }
  }

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

}

//--------------------------------------------------------------------------------------------------
