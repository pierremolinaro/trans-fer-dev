//
//  SyntaxHighlightingTextEditor.swift
//  text-syntax-coloring-2-views
//
//  Created by Pierre Molinaro on 12/08/2025.
//
//--------------------------------------------------------------------------------------------------

import SwiftUI
// import Combine // Required for ObservableObject
import AppKit

//--------------------------------------------------------------------------------------------------

class TextLogger : NSObject, NSTextStorageDelegate { // , ObservableObject {

  fileprivate var mTextStorage : NSTextStorage = NSTextStorage ()
  fileprivate var mFont = NSFont.monospacedSystemFont (ofSize: 12.0, weight: .regular)

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  override init () {
    super.init ()
    self.mTextStorage.delegate = self
    self.mTextStorage.font = self.mFont
    let attributes : [NSAttributedString.Key : Any] = [
      .font: self.mFont
    ]
    let at = NSAttributedString (string: "Hello", attributes: attributes)
//    self.mTextStorage.beginEditing ()
    self.mTextStorage.setAttributedString (at)
//    self.mTextStorage.endEditing ()
  }

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  func removeAll () {
//    self.mTextStorage.beginEditing ()
    let attributes : [NSAttributedString.Key : Any] = [
      .font: self.mFont,
      .foregroundColor: NSColor.blue
    ]
    self.mTextStorage.setAttributedString (NSAttributedString (string: "Cleared", attributes: attributes))
//    self.mTextStorage.endEditing ()
  }

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  func appendCommandString (_ inMessage : String) {
    self.mTextStorage.beginEditing ()
    let attributes : [NSAttributedString.Key : Any] = [
      .font: self.mFont,
      .foregroundColor: NSColor.blue
    ]
    let at = NSAttributedString (string: inMessage, attributes: attributes)
    self.mTextStorage.append (at)
    self.mTextStorage.endEditing ()
    RunLoop.current.run (mode: .default, before: Date ())
  }

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  func appendMessageString (_ inMessage : String) {
    self.mTextStorage.beginEditing ()
    let attributes : [NSAttributedString.Key : Any] = [
      .font: self.mFont,
      .foregroundColor: NSColor.black
    ]
    let at = NSAttributedString (string: inMessage, attributes: attributes)
    self.mTextStorage.append (at)
    self.mTextStorage.endEditing ()
    RunLoop.current.run (mode: .default, before: Date ())
  }

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  func appendSuccessString (_ inMessage : String) {
    self.mTextStorage.beginEditing ()
    let attributes : [NSAttributedString.Key : Any] = [
      .font: self.mFont,
      .foregroundColor: NSColor.green
    ]
    let at = NSAttributedString (string: inMessage, attributes: attributes)
    self.mTextStorage.append (at)
    self.mTextStorage.endEditing ()
    RunLoop.current.run (mode: .default, before: Date ())
  }

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  func appendErrorString (_ inMessage : String) {
    self.mTextStorage.beginEditing ()
    let attributes : [NSAttributedString.Key : Any] = [
      .font: self.mFont,
      .foregroundColor: NSColor.red
    ]
    let at = NSAttributedString (string: inMessage, attributes: attributes)
    self.mTextStorage.append (at)
    self.mTextStorage.endEditing ()
    RunLoop.current.run (mode: .default, before: Date ())
  }

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  func textStorage (_ textStorage: NSTextStorage,
                   didProcessEditing editedMask: NSTextStorageEditActions,
                   range editedRange: NSRange,
                   changeInLength delta: Int) { // NSTextStorageDelegate
//    Swift.print ("textStorage:didProcessEditing \(self.mTextStorage.attributedSubstring(from: .init(location: 0, length: self.mTextStorage.length)))")
    Swift.print ("textStorage:didProcessEditing \(self.mTextStorage.length)))")
//    let _ = self.mTextStorage.string
      let nsString = self.mTextStorage.string as NSString
      let fullRange = NSRange (location: 0, length: nsString.length)
//      ps.lineHeightMultiple = CGFloat (self.mLineHeight) / 10.0
      let defaultAttributes : [NSAttributedString.Key : Any] = [
        .font: self.mFont,
        .foregroundColor: NSColor.red,
//        .paragraphStyle : ps
      ]
      self.mTextStorage.setAttributes (defaultAttributes, range: fullRange)
  }

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

}

//--------------------------------------------------------------------------------------------------

struct TextLoggerView : NSViewRepresentable {

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  var mSharedTextLogger : TextLogger
  let mLayoutManager = NSLayoutManager ()

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  init (_ inSharedTextLogger : TextLogger) {
    self.mSharedTextLogger = inSharedTextLogger
  }

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

//  func makeCoordinator () -> TextLoggerViewCoordinator {
//    return TextLoggerViewCoordinator (self)
//  }

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  func makeNSView (context inContext : Context) -> NSScrollView {
  //--- Création du layout manager
    self.mLayoutManager.allowsNonContiguousLayout = true
    self.mSharedTextLogger.mTextStorage.addLayoutManager (self.mLayoutManager)
  //-- Création du container relié
    let greatestSize = NSSize (
      width: CGFloat.greatestFiniteMagnitude,
      height: CGFloat.greatestFiniteMagnitude
    )
    let textContainer = NSTextContainer (size: greatestSize)
    self.mLayoutManager.addTextContainer (textContainer)
    let textView = NSTextView (frame: .zero, textContainer: textContainer)

    textView.allowsUndo = false
    textView.isRichText = true
    textView.isAutomaticDataDetectionEnabled = false
    textView.isAutomaticLinkDetectionEnabled = false
    textView.isAutomaticTextCompletionEnabled = false
    textView.isAutomaticTextReplacementEnabled = false
    textView.isAutomaticDashSubstitutionEnabled = false
    textView.isAutomaticQuoteSubstitutionEnabled = false
    textView.isAutomaticSpellingCorrectionEnabled = false
    textView.isEditable = false
    textView.isSelectable = true
    textView.minSize = NSSize (width: 100, height: 100)
    textView.maxSize = greatestSize
    textView.isHorizontallyResizable = true
    textView.isVerticallyResizable = true
    textView.autoresizingMask = [.width]
  //--- Garde la référence
//    inContext.coordinator.mTextView = textView
  //--- ScrollView
    let scrollView = NSScrollView ()
    scrollView.documentView = textView
    scrollView.hasVerticalScroller = true
    scrollView.autohidesScrollers = false
    return scrollView
  }

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  func updateNSView (_ inUnusedScrollView : NSScrollView,
                     context inUnusedContext : Context) {
//    Swift.print ("updateNSView '\(self.mSharedTextLogger.mTextStorage.string)'")
//    self.mTextView.needsDisplay = true
//    Swift.print ("updateNSView: \(ObjectIdentifier (self.mSharedTextLogger.mTextStorage))")
  }

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

}

//--------------------------------------------------------------------------------------------------

//final class TextLoggerViewCoordinator { // : NSObject {
//
//  private let mParent : TextLoggerView
//
//  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
//
//  init (_ inParent : TextLoggerView) {
//    self.mParent = inParent
////    super.init ()
//  }
//
//  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
//
//}

//--------------------------------------------------------------------------------------------------
