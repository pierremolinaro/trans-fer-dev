//
//  MyTextField.swift
//  TextField-focus-changes-edited-state
//
//  Created by Pierre Molinaro on 20/08/2025.
//
//--------------------------------------------------------------------------------------------------

import SwiftUI

//--------------------------------------------------------------------------------------------------

struct MyTextField : View {

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  let mTitle : String
  @Binding var mExportedText : String
  @State var mInternalText : String

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  init (_ inTitle : String, text inTextBinding : Binding <String>) {
    self.mTitle = inTitle
    self._mExportedText = inTextBinding
    self.mInternalText = inTextBinding.wrappedValue
  }

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  var body: some View {
    TextField (self.mTitle, text: self.$mInternalText)
    .onChange (of: self.mInternalText) { newValue in
      if self.mInternalText != newValue {
       self.mExportedText = newValue
      }
    }
    .onChange (of: self.mExportedText) { newValue in
      if self.mExportedText != newValue {
        self.mInternalText = newValue
      }
    }
//    .onChange (of: self.mInternalText) { (oldValue, newValue) in
//      if oldValue != newValue {
//       self.mExportedText = newValue
//      }
//    }
//    .onChange (of: self.mExportedText, initial: true) { (oldValue, newValue) in
//      if oldValue != newValue {
//        self.mInternalText = newValue
//      }
//    }
  }

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

}

//--------------------------------------------------------------------------------------------------
