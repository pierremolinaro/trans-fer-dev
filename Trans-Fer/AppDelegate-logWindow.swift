//
//  AppDelegate-logWindow.swift
//  FlashagePic
//
//  Created by Pierre Molinaro on 11/02/2022.
//
//——————————————————————————————————————————————————————————————————————————————————————————————————

import AppKit

//——————————————————————————————————————————————————————————————————————————————————————————————————

@MainActor func showLogWindow () {
  gAppDelegate?.mLogWindow?.makeKeyAndOrderFront (nil)
}

//——————————————————————————————————————————————————————————————————————————————————————————————————

@MainActor func clearLogWindow () {
  gAppDelegate?.clear ()
}

//——————————————————————————————————————————————————————————————————————————————————————————————————

@MainActor func appendMessageString (_ inString : String) {
  gAppDelegate?.appendMessageString (inString)
}

//——————————————————————————————————————————————————————————————————————————————————————————————————

@MainActor func appendCommandString (_ inString : String) {
  gAppDelegate?.appendCommandString (inString)
}

//——————————————————————————————————————————————————————————————————————————————————————————————————

@MainActor func appendErrorString (_ inString : String) {
  gAppDelegate?.appendErrorString (inString)
}

//——————————————————————————————————————————————————————————————————————————————————————————————————

@MainActor func appendWarningString (_ inString : String) {
  gAppDelegate?.appendWarningString (inString)
}

//——————————————————————————————————————————————————————————————————————————————————————————————————

@MainActor func appendSuccessString (_ inString : String) {
  gAppDelegate?.appendSuccessString (inString)
}

//——————————————————————————————————————————————————————————————————————————————————————————————————

extension AppDelegate {

  //································································································

  func clear () {
    if let ts = self.mLogTextView?.layoutManager?.textStorage {
      let str = NSAttributedString (string: "", attributes: nil)
      ts.setAttributedString (str)
    }
  }

  //····················································································································

  func appendAttributedString (_ inAttributedString : NSAttributedString) {
    if let ts = self.mLogTextView?.layoutManager?.textStorage {
      ts.append (inAttributedString)
      let endOfText = NSRange (location: ts.length, length: 0)
      self.mLogTextView?.scrollRangeToVisible (endOfText)
    }
  }

  //····················································································································

  func appendMessageString (_ inString : String) {
    let attributes : [NSAttributedString.Key : NSObject] = [
      NSAttributedString.Key.font : NSFont.boldSystemFont (ofSize: NSFont.smallSystemFontSize),
      NSAttributedString.Key.foregroundColor : NSColor.black
    ]
    let str = NSAttributedString (string:inString, attributes:attributes)
    self.appendAttributedString (str)
  }

  //····················································································································

  func appendMessageString (_ inString : String, color : NSColor) {
    let attributes : [NSAttributedString.Key : NSObject] = [
      NSAttributedString.Key.font : NSFont.boldSystemFont (ofSize: NSFont.smallSystemFontSize),
      NSAttributedString.Key.foregroundColor : color
    ]
    let str = NSAttributedString (string:inString, attributes: attributes)
    self.appendAttributedString (str)
  }

  //····················································································································

  func appendCodeString (_ inString : String, color : NSColor) {
    let font = NSFont.userFixedPitchFont (ofSize: NSFont.smallSystemFontSize) ?? NSFont.boldSystemFont (ofSize: NSFont.smallSystemFontSize)
    let attributes : [NSAttributedString.Key : NSObject] = [
      NSAttributedString.Key.font : font,
      NSAttributedString.Key.foregroundColor : color
    ]
    let str = NSAttributedString (string: inString, attributes: attributes)
    self.appendAttributedString (str)
  }

  //····················································································································

  func appendCommandString (_ inString : String) {
    self.appendMessageString (inString, color: .systemBlue)
  }

  //····················································································································

  func appendErrorString (_ inString : String) {
    self.appendMessageString (inString, color: .systemRed)
  }

  //····················································································································

  func appendWarningString (_ inString : String) {
    self.appendMessageString (inString, color: .systemOrange)
  }

  //····················································································································

  func appendSuccessString (_ inString : String) {
    self.appendMessageString (inString, color: .systemGreen)
  }

  //································································································

}

//——————————————————————————————————————————————————————————————————————————————————————————————————
