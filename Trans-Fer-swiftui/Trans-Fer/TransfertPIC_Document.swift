//
//  TransfertPIC_Document.swift
//  Trans-Fer
//
//  Created by Pierre Molinaro on 16/08/2025.
//
//--------------------------------------------------------------------------------------------------

import SwiftUI
import UniformTypeIdentifiers

//--------------------------------------------------------------------------------------------------

nonisolated struct TransfertPIC_Document : FileDocument {

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  static let readableContentTypes = [
    UTType (importedAs: "name.pcmolinaro.pierre.Trans-Fer.TransfertPIC")
  ]

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  var mNomFirmware : String = ""
  var mNomUpdater : String = ""
  var mOptimisation : Bool = true
  var mSignature : String = "??????"
  var mAdressesCAN : String = ""

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  init() {
  }

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    init (configuration inReadConfiguration : ReadConfiguration) throws {
      if let data = inReadConfiguration.file.regularFileContents,
         let str = String (data: data, encoding: .utf8) {
        let components = str.components (separatedBy: "\n")
        self.mNomFirmware = components [0]
        self.mNomUpdater = components [1]
        self.mOptimisation = components [2] == "1"
        self.mSignature = components [3]
        self.mAdressesCAN = components [4]
      }else{
        throw CocoaError(.fileReadCorruptFile)
      }
    }

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  func fileWrapper (configuration inWriteConfiguration : WriteConfiguration) throws -> FileWrapper {
    var s = self.mNomFirmware + "\n"
    s += self.mNomUpdater + "\n"
    s += (self.mOptimisation ? "1" : "0") + "\n"
    s += self.mSignature + "\n"
    s += self.mAdressesCAN + "\n"
    let data = s.data (using: .utf8)!
    return .init (regularFileWithContents: data)
  }

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

}

//--------------------------------------------------------------------------------------------------
