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

  //································································································

  func appendAttributedString (_ inAttributedString : NSAttributedString) {
    if let ts = self.mLogTextView?.layoutManager?.textStorage {
      ts.append (inAttributedString)
      let endOfText = NSRange (location: ts.length, length: 0)
      self.mLogTextView?.scrollRangeToVisible (endOfText)
    }
  }

  //································································································

  func appendMessageString (_ inString : String) {
    let attributes : [NSAttributedString.Key : Any] = [
      .font : NSFont.boldSystemFont (ofSize: NSFont.systemFontSize),
      .foregroundColor : NSColor.black
    ]
    let str = NSAttributedString (string: inString, attributes: attributes)
    self.appendAttributedString (str)
  }

  //································································································

  func appendMessageString (_ inString : String, color inColor : NSColor) {
    let attributes : [NSAttributedString.Key : Any] = [
      .font : NSFont.boldSystemFont (ofSize: NSFont.systemFontSize),
      .foregroundColor : inColor
    ]
    let str = NSAttributedString (string: inString, attributes: attributes)
    self.appendAttributedString (str)
  }

  //································································································

  func appendCodeString (_ inString : String, color inColor : NSColor) {
    let font = NSFont.userFixedPitchFont (ofSize: NSFont.systemFontSize) ?? NSFont.boldSystemFont (ofSize: NSFont.systemFontSize)
    let attributes : [NSAttributedString.Key : Any] = [
      .font : font,
      .foregroundColor : inColor
    ]
    let str = NSAttributedString (string: inString, attributes: attributes)
    self.appendAttributedString (str)
  }

  //································································································

  func appendCommandString (_ inString : String) {
    self.appendMessageString (inString, color: .systemBlue)
  }

  //································································································

  func appendErrorString (_ inString : String) {
    self.appendMessageString (inString, color: .systemRed)
  }

  //································································································

  func appendWarningString (_ inString : String) {
    self.appendMessageString (inString, color: .systemOrange)
  }

  //································································································

  func appendSuccessString (_ inString : String) {
    self.appendMessageString (inString, color: .systemGreen)
  }

  //································································································

}

//——————————————————————————————————————————————————————————————————————————————————————————————————
