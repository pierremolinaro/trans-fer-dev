//
//  SyntaxHighlightingTextEditor.swift
//  text-syntax-coloring-2-views
//
//  Created by Pierre Molinaro on 12/08/2025.
//
//--------------------------------------------------------------------------------------------------

import SwiftUI
import AppKit

//--------------------------------------------------------------------------------------------------

class TextLogger : NSObject {

  fileprivate var mTextStorage : NSTextStorage = NSTextStorage ()
  fileprivate var mFont = NSFont.monospacedSystemFont (ofSize: 12.0, weight: .regular)

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  override init () {
    super.init ()
    self.mTextStorage.font = self.mFont
    let attributes : [NSAttributedString.Key : Any] = [
      .font: self.mFont
    ]
    let at = NSAttributedString (string: "", attributes: attributes)
    self.mTextStorage.beginEditing ()
    self.mTextStorage.setAttributedString (at)
    self.mTextStorage.endEditing ()
  }

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  func removeContent () {
    let attributes : [NSAttributedString.Key : Any] = [
      .font: self.mFont,
      .foregroundColor: NSColor.blue
    ]
    self.mTextStorage.beginEditing ()
    self.mTextStorage.setAttributedString (NSAttributedString (string: "", attributes: attributes))
    self.mTextStorage.endEditing ()
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

}

//--------------------------------------------------------------------------------------------------

struct TextLoggerView : NSViewRepresentable {

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  var mSharedTextLogger : TextLogger
  let mLayoutManager = NSLayoutManager ()
  let mTextView : NSTextView

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  init (_ inSharedTextLogger : TextLogger) {
    self.mSharedTextLogger = inSharedTextLogger
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
    self.mTextView = NSTextView (frame: .zero, textContainer: textContainer)
  }

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  func makeCoordinator () -> LoggerViewCoordinator {
    return LoggerViewCoordinator (self)
  }

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  func makeNSView (context inContext : Context) -> NSScrollView {
    self.mTextView.allowsUndo = false
    self.mTextView.isRichText = true
    self.mTextView.isAutomaticDataDetectionEnabled = false
    self.mTextView.isAutomaticLinkDetectionEnabled = false
    self.mTextView.isAutomaticTextCompletionEnabled = false
    self.mTextView.isAutomaticTextReplacementEnabled = false
    self.mTextView.isAutomaticDashSubstitutionEnabled = false
    self.mTextView.isAutomaticQuoteSubstitutionEnabled = false
    self.mTextView.isAutomaticSpellingCorrectionEnabled = false
    self.mTextView.isEditable = false
    self.mTextView.isSelectable = true
    self.mTextView.minSize = .zero
    self.mTextView.maxSize = NSSize (
      width: CGFloat.greatestFiniteMagnitude,
      height: CGFloat.greatestFiniteMagnitude
    )
    self.mTextView.isHorizontallyResizable = true
    self.mTextView.isVerticallyResizable = true
    self.mTextView.autoresizingMask = [.width, .height]
  //--- ScrollView
    let scrollView = NSScrollView ()
    scrollView.documentView = self.mTextView
    scrollView.hasVerticalScroller = true
    scrollView.autohidesScrollers = false
    return scrollView
  }

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  func updateNSView (_ inUnusedScrollView : NSScrollView,
                     context inUnusedContext : Context) {
  }

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

}

//--------------------------------------------------------------------------------------------------

class LoggerViewCoordinator : NSObject, NSTextViewDelegate {

  let mParent : TextLoggerView

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  init (_ inParent : TextLoggerView) {
    self.mParent = inParent
    super.init ()
    self.mParent.mTextView.delegate = self
  }

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  func textViewDidChangeSelection (_ inUnusedNotification : Notification) {  // NSTextViewDelegate
    self.mParent.mTextView.scrollToEndOfDocument (nil)
  }

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

}

//--------------------------------------------------------------------------------------------------
