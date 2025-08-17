//
//  TransfertParFTP.swift
//  Trans-Fer
//
//  Created by Pierre Molinaro on 17/08/2025.
//
//--------------------------------------------------------------------------------------------------

import AppKit

//--------------------------------------------------------------------------------------------------

final class TransfertParFTP : NSObject {

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  private var mAlert : NSAlert? = nil
  private var mData = Data ()
  private var mMessageStringCallBack : Optional <(String) -> Void> = nil

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  func runCancelableCommand (command cmd : String,
                             arguments args : [String],
                             processCurrentDirectoryPath inProcessCurrentDirectoryPath : String,
                             window inWindow : NSWindow,
                             alertTitle inTitle : String,
                             commandStringHandler inCommandStringCallBack : @escaping (String) -> Void,
                             messageStringHandler inMessageStringCallBack : @escaping (String) -> Void,
                             terminationHandler inCallBack : @escaping @Sendable (_ inStatus : Int32) -> Void) {
    self.mMessageStringCallBack = inMessageStringCallBack
  //--- Command String
    var str = "+ " + cmd
    for s in args {
      str += " " + s
    }
    inCommandStringCallBack (str + "\n")
  //--- Run Command
    let process = Process ()
    process.launchPath = cmd
    process.arguments = args
    process.currentDirectoryPath = inProcessCurrentDirectoryPath
    let pipe = Pipe ()
    process.standardOutput = pipe
    process.standardError = pipe
    let stdoutHandle = pipe.fileHandleForReading
    stdoutHandle.waitForDataInBackgroundAndNotify ()
    self.mData = Data ()
    NotificationCenter.default.addObserver (
      self,
      selector: #selector (Self.receivedData (_:)),
      name: NSNotification.Name.NSFileHandleDataAvailable,
      object: stdoutHandle
    )
  //--- Display Panel ?
    let alert = NSAlert ()
    self.mAlert = alert
    alert.messageText = inTitle
    alert.addButton (withTitle: "Arrêter")
    alert.beginSheetModal (for: inWindow) { (_ inResponse : NSApplication.ModalResponse) in
      NotificationCenter.default.removeObserver (
        self,
        name: NSNotification.Name.NSFileHandleDataAvailable,
        object: stdoutHandle
      )
      DispatchQueue.main.async {
        self.mAlert = nil
        if process.isRunning {
          process.terminate ()
          inCallBack (1)
        }else{
          let status = process.terminationStatus
          inCallBack (status)
        }
      }
    }
  //--- Launch command
    process.launch ()
  }

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  @objc private func receivedData (_ inNotification : NSNotification) {
    if let fileHandle = inNotification.object as? FileHandle {
      let newData = fileHandle.availableData
      if newData.count > 0 {
        self.mData.append (newData)
        if let str = String (data: self.mData, encoding: .utf8) {
          DispatchQueue.main.async { self.mMessageStringCallBack? (str) }
          fileHandle.waitForDataInBackgroundAndNotify ()
          self.mData = Data ()
        }
      }else if let button = self.mAlert?.buttons.last {
        button.performClick (nil)
      }
    }
  }

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

}

//--------------------------------------------------------------------------------------------------
