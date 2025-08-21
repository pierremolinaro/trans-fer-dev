//
//  TransfertParFTP.swift
//  Trans-Fer
//
//  Created by Pierre Molinaro on 17/08/2025.
//
//--------------------------------------------------------------------------------------------------

import AppKit
import SwiftUI

//--------------------------------------------------------------------------------------------------

final class TransfertParFTP : NSObject {

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  private var mAlert : NSAlert? = nil
  private var mData = Data ()
  private var mMessageStringCallBack : Optional <(String) -> Void> = nil
  private var mTerminationSuccessHandler : Optional <() -> Void> = nil
  private var mResult : Int32 = 0
  var result : Int32 { return self.mResult }

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  func runCancelableCommand (command cmd : String,
                             arguments args : [String],
                             processCurrentDirectoryPath inProcessCurrentDirectoryPath : String,
                             alertState inAlertState : Binding <Bool>,
                             commandStringHandler inCommandStringCallBack : @escaping (String) -> Void,
                             messageStringHandler inMessageStringCallBack : @escaping (String) -> Void,
                             terminationSuccessHandler inTerminationSuccessHandler : @escaping () -> Void) {
    self.mMessageStringCallBack = inMessageStringCallBack
    self.mTerminationSuccessHandler = inTerminationSuccessHandler
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
  //--- Display Alert
    inAlertState.wrappedValue = true
//    let alert = NSAlert ()
//    self.mAlert = alert
//    alert.messageText = "???"
//    alert.addButton (withTitle: "Arrêter")
//    alert.beginSheetModal (for: inWindow) { (_ inResponse : NSApplication.ModalResponse) in
//      NotificationCenter.default.removeObserver (
//        self,
//        name: NSNotification.Name.NSFileHandleDataAvailable,
//        object: stdoutHandle
//      )
//      DispatchQueue.main.async {
//        self.mAlert = nil
//        if process.isRunning {
//          process.terminate ()
//          self.mResult = 1
//          inCallBack (1)
//        }else{
//          self.mResult = process.terminationStatus
//          inCallBack (status)
//        }
//      }
//    }
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
      }else {
        self.mTerminationSuccessHandler? ()
      }
    }
  }

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

}

//--------------------------------------------------------------------------------------------------
