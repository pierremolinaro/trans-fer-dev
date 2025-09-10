//
//  DocumentTransfertRP2040.swift
//  Trans-Fer
//
//  Created by Pierre Molinaro on 18/04/2022.
//
//——————————————————————————————————————————————————————————————————————————————————————————————————

import AppKit

//——————————————————————————————————————————————————————————————————————————————————————————————————

fileprivate let ARDUINO_BUILD_DIR = "arduino-build"
fileprivate let DEFAULT_PLATFORM = "rp2040:rp2040:rpipico:flash=2097152_0,freq=125,opt=Small,rtti=Disabled,dbgport=Disabled,dbglvl=None,usbstack=picosdk"

//——————————————————————————————————————————————————————————————————————————————————————————————————

@objc(DocumentTransfertRP2040) class DocumentTransfertRP2040 : NSDocument {

  //································································································

  @IBOutlet var mNomDossierCroquisTextField : NSTextField? = nil
  @IBOutlet var mSignatureTextField : NSTextField? = nil
  @IBOutlet var mAdressesTextField : NSTextField? = nil
  @IBOutlet var mPlatformTextField : NSTextField? = nil

  @IBOutlet var mCommandeCompilationButton : NSButton? = nil
  @IBOutlet var mImageSuccessCompilation : NSImageView? = nil

  @IBOutlet var mCommandeTransformerElfEnBinButton : NSButton? = nil
  @IBOutlet var mImageSuccessTransformationElfEnBin : NSImageView? = nil

  @IBOutlet var mCommandeTransformerEnBinPicButton : NSButton? = nil
  @IBOutlet var mImageSuccessTransformationEnBinPic : NSImageView? = nil

  @IBOutlet var mCommandeTransfererParFTPButton : NSButton? = nil
  @IBOutlet var mImageSuccessTransfererEnFTP : NSImageView? = nil

  private var mAlert : NSAlert? = nil
  private var mData = Data ()

  //····················································································································
  //    init
  //····················································································································

  override init () {
    super.init ()
  }
  
  //································································································

  @objc private dynamic var mChainePlatforme : String = DEFAULT_PLATFORM {
    didSet {
      self.undoManager?.registerUndo (withTarget: self) {
        $0.willChangeValue (forKey: "mChainePlatforme")
        $0.mChainePlatforme = oldValue
        $0.didChangeValue (forKey: "mChainePlatforme")
      }
    }
  }

  //································································································

  @objc private dynamic var mNomDossierCroquis : String = "" {
    didSet {
      self.undoManager?.registerUndo (withTarget: self) {
        $0.willChangeValue (forKey: "mNomDossierCroquis")
        $0.mNomDossierCroquis = oldValue
        $0.didChangeValue (forKey: "mNomDossierCroquis")
      }
    }
  }

  //································································································

  var nomDossierCroquis : String { self.mNomDossierCroquis }

  //································································································

  @objc private dynamic var mSignature : String = "??????" {
    didSet {
      self.undoManager?.registerUndo (withTarget: self) {
        $0.willChangeValue (forKey: "mSignature")
        $0.mSignature = oldValue
        $0.didChangeValue (forKey: "mSignature")
      }
    }
  }

  //································································································

  @objc private dynamic var mAdressesCAN : String = "" {
    didSet {
      self.undoManager?.registerUndo (withTarget: self) {
        $0.willChangeValue (forKey: "mAdressesCAN")
        $0.mAdressesCAN = oldValue
        $0.didChangeValue (forKey: "mAdressesCAN")
      }
    }
  }

  //································································································

  override var windowNibName: NSNib.Name? {
    return NSNib.Name ("DocumentTransfertRP2040")
  }

  //································································································

  override func data (ofType typeName: String) throws -> Data {
    var s = self.mNomDossierCroquis + "\n"
    s += self.mSignature + "\n"
    s += self.mAdressesCAN + "\n"
    s += self.mChainePlatforme
    let data = s.data (using: .utf8)!
    return data
  }

  //································································································

  nonisolated override func read (from inData : Data, ofType typeName: String) throws {
    DispatchQueue.main.async {
      self.undoManager?.disableUndoRegistration ()
        let s = String (data: inData, encoding: .utf8)!
        let components = s.components (separatedBy: "\n")
        self.mNomDossierCroquis = components [0]
        self.mSignature = components [1]
        self.mAdressesCAN = components [2]
        if components.count > 3, !components [3].isEmpty {
          self.mChainePlatforme = components [3]
        }
      self.undoManager?.enableUndoRegistration ()
    }
  }

  //································································································

  override func windowControllerDidLoadNib (_ windowController : NSWindowController) {
    self.mPlatformTextField?.bind (
      .value,
      to: self,
      withKeyPath: "mChainePlatforme",
      options: [NSBindingOption.continuouslyUpdatesValue : true]
    )
    self.mNomDossierCroquisTextField?.bind (
      .value,
      to: self,
      withKeyPath: "mNomDossierCroquis",
      options: [NSBindingOption.continuouslyUpdatesValue : true]
    )
    self.mSignatureTextField?.bind (
      .value,
      to: self,
      withKeyPath: "mSignature",
      options: [NSBindingOption.continuouslyUpdatesValue : true]
    )
    self.mAdressesTextField?.bind (
      .value,
      to: self,
      withKeyPath: "mAdressesCAN",
      options: [NSBindingOption.continuouslyUpdatesValue : true]
    )
    super.windowControllerDidLoadNib (windowController)
  }

  //································································································
  //  runCancelableCommand
  //································································································

  func runCancelableCommand (_ cmd : String,
                             _ args : [String],
                             alertTitle inTitle : String,
                             _ inCallBack : @escaping @MainActor (_ inStatus : Int32) -> Void) {
  //--- Command String
    var str = "+ " + cmd
    for s in args {
      str += " " + s
    }
    appendCommandString (str + "\n")
    if let documentDir = self.fileURL?.deletingLastPathComponent ().path {
    //--- Run Command
      let process = Process ()
      process.launchPath = cmd
      process.arguments = args
      process.currentDirectoryPath = documentDir
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
      alert.beginSheetModal (for: self.windowForSheet!) { (_ inResponse : NSApplication.ModalResponse) in
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
    }else{
      appendErrorString ("Cannot run, the document is not saved.\n")
      inCallBack (1)
    }
  }

  //································································································

  @objc func receivedData (_ inNotification : NSNotification) {
    if let fileHandle = inNotification.object as? FileHandle {
      let newData = fileHandle.availableData
      if newData.count > 0 {
        self.mData.append (newData)
        if let str = String (data: self.mData, encoding: .utf8) {
          DispatchQueue.main.async { appendMessageString (str) }
          fileHandle.waitForDataInBackgroundAndNotify ()
          self.mData = Data ()
        }
      }else if let button = self.mAlert?.buttons.last {
        button.performClick (nil)
      }
    }
  }

  //································································································

  func runCommand (prefix inPrefix : String, _ inCommand : String, _ inArgs : [String]) -> Int32 {
  //--- Command String
    var str = inPrefix + " " + inCommand
    for s in inArgs {
      str += " " + s
    }
    str += "\n"
    appendCommandString (str)
    if let documentDir = self.fileURL?.deletingLastPathComponent ().path {
    //--- Run Command
      let task = Process ()
      task.launchPath = inCommand
      task.arguments = inArgs
      task.currentDirectoryPath = documentDir
      let pipe = Pipe ()
      task.standardOutput = pipe
      task.standardError = pipe
      let stdoutHandle = pipe.fileHandleForReading
      DispatchQueue.global (qos: .background).async {
        var newData = stdoutHandle.availableData
        var data = Data ()
        while newData.count > 0 {
          data.append (newData)
          if let str = String (data: data, encoding: .utf8) {
            DispatchQueue.main.async { appendMessageString (str) }
            data = Data ()
          }
          newData = stdoutHandle.availableData
        }
      }
      task.launch ()
    //--- Task completed
      task.waitUntilExit ()
      let status = task.terminationStatus
    //---
      return status
    }else{
      appendErrorString ("Cannot run, the document is not saved.\n")
      return 1
    }
  }

  //································································································

  @IBAction func showLogWindowAction (_ inSender : Any?) {
    showLogWindow ()
  }

  //································································································

  fileprivate func effacerAvantOperations () {
    clearLogWindow () ;
    self.mImageSuccessCompilation?.image = nil
    self.mImageSuccessTransformationElfEnBin?.image = nil
    self.mImageSuccessTransformationEnBinPic?.image = nil
    self.mImageSuccessTransfererEnFTP?.image = nil
  }

  //································································································

  private func commandeCompilationCroquisArduino () -> (String, [String]) {
    let commandeArduinoCli = UserDefaults.standard.string (forKey: PREFS_ARDUINO_CLI_TOOL) ?? "?"
//    let PLATFORM = "rp2040:rp2040:rpipico:flash=2097152_0,freq=125,opt=Small,rtti=Disabled,dbgport=Disabled,dbglvl=None,usbstack=picosdk"
    let documentDir = self.fileURL?.deletingLastPathComponent ().path ?? "?"
    let BUILD_PATH = documentDir + "/" + ARDUINO_BUILD_DIR
    var arguments = [String] ()
    arguments.append ("compile")
    arguments.append ("-b=" + self.mChainePlatforme)
    arguments.append ("--build-path")
    arguments.append (BUILD_PATH)
    arguments.append ("--no-color")
    arguments.append ("--warnings=all")
    arguments.append (documentDir + "/" + self.mNomDossierCroquis)
    return (commandeArduinoCli, arguments)
  }

  //································································································

  private func commandeCompîlationUpdaterPiccolo () -> (String, [String]) {
    let commande = (UserDefaults.standard.string (forKey: PREFS_PICCOLO_APP) ?? "?") + "/Contents/Resources/piccolo"
    var arguments = [String] ()
    arguments.append ("--Werror")
    arguments.append ("-S")
    arguments.append ("-O")
    arguments.append ("-L")
    arguments.append ("--no-color")
    return (commande, arguments)
  }

  //································································································

  fileprivate func compilerCroquisArduino (_ ioSuccess : inout Bool) {
    self.mImageSuccessCompilation?.image = NSImage (named: "NSSmartBadgeTemplate")
    let (command, arguments) = self.commandeCompilationCroquisArduino ()
    let result = self.runCommand (prefix: "① ", command, arguments)
    if result == 0 {
      appendSuccessString ("Succès\n")
      self.mImageSuccessCompilation?.image = NSImage (named: "NSStatusAvailable")
    }else{
      appendErrorString ("Échec (erreur \(result))\n")
      self.mImageSuccessCompilation?.image = NSImage (named: "NSStatusUnavailable")
      showLogWindow ()
      ioSuccess = false
    }
  }

  //································································································

  private func commandTransformerElfEnBin () -> (String, [String]) {
    let outilsTrainP2M2 = NSHomeDirectory () + "/outils-train-p2m2/"
    let fm = FileManager ()
    var commande = outilsTrainP2M2 + "???"
    if let dirs = try? fm.contentsOfDirectory (atPath: outilsTrainP2M2) {
      for aDir in dirs {
        let f = outilsTrainP2M2 + aDir + "/bin/arm-none-eabi-objcopy"
        // Swift.print ("f '\(f)'")
        if fm.fileExists (atPath: f) {
          commande = f
          break
        }
      }
    }
    let documentDir = self.fileURL?.deletingLastPathComponent ().path ?? "?"
    let BUILD_PATH = documentDir + "/" + ARDUINO_BUILD_DIR
    var arguments = [String] ()
    arguments.append ("-O")
    arguments.append ("binary")
    arguments.append (BUILD_PATH + "/" + self.mNomDossierCroquis + ".ino.elf")
    arguments.append (BUILD_PATH + "/" + self.mNomDossierCroquis + ".bin")
    return (commande, arguments)
  }

  //································································································

  fileprivate func transformerElfEnBin (_ ioSuccess : inout Bool) {
    self.mImageSuccessTransformationElfEnBin?.image = NSImage (named: "NSSmartBadgeTemplate")
    let (command, arguments) = self.commandTransformerElfEnBin ()
    let result = self.runCommand (prefix: "② ", command, arguments)
    if result == 0 {
      appendSuccessString ("Succès\n")
      self.mImageSuccessTransformationElfEnBin?.image = NSImage (named: "NSStatusAvailable")
    }else{
      appendErrorString ("Échec (erreur \(result))\n")
      self.mImageSuccessTransformationElfEnBin?.image = NSImage (named: "NSStatusUnavailable")
      ioSuccess = false
    }
  }

  //································································································

  @IBAction func compileAction (_ inSender : Any?) {
    self.effacerAvantOperations () ;
    var success = true
    compilerCroquisArduino (&success)
  }

  //································································································

  @IBAction func transformToPiccoloDataAction (_ inSender : Any?) {
    self.effacerAvantOperations () ;
    var success = true
    self.compilerCroquisArduino (&success)
    if success {
      self.transformerElfEnBin (&success)
    }
  }

  //································································································

  fileprivate func transformerEnBinPic (_ ioSuccess : inout Bool) {
    self.mImageSuccessTransformationEnBinPic?.image = NSImage (named: "NSSmartBadgeTemplate")
    let adressesPIC = self.mAdressesCAN.components (separatedBy: " ").joined (separator: "")
    var (array, result) = parsePicsCible (adressesPIC)
    if result == 0 {
       result = construireFichierBinaireDistribution (array, self.mSignature)
    }
    if result == 0 {
      appendSuccessString ("Succès\n")
      self.mImageSuccessTransformationEnBinPic?.image = NSImage (named: "NSStatusAvailable")
    }else{
      appendErrorString ("Échec (erreur \(result))\n")
      self.mImageSuccessTransformationEnBinPic?.image = NSImage (named: "NSStatusUnavailable")
      ioSuccess = false
    }
  }

  //································································································

  @IBAction func transformToBinPicAction (_ inSender : Any?) {
    self.effacerAvantOperations () ;
    var success = true
    self.compilerCroquisArduino (&success)
    if success {
      self.transformerElfEnBin (&success)
    }
    if success {
      self.transformerEnBinPic (&success)
    }
  }

  //································································································
  //  Transférer par FTP
  //································································································

  private func commandeTransférerParFTP () -> (String, [String]) {
    let commande = "/usr/bin/curl"
    var arguments = [String] ()
    arguments.append ("-L") // Follow redirections
    arguments.append ("-s") // Silent mode, do not show download progress
 //   arguments.append ("-k") // Turn off curl's verification of certificate
    arguments.append ("-T")
    arguments.append (ARDUINO_BUILD_DIR + "/" + self.mSignature + ".binpic")
    let ip = UserDefaults.standard.string (forKey: PREFS_ADRESSE_IP_CARTE_MEZZANINE) ?? "?"
    arguments.append ("ftp://\(ip)/" + self.mSignature + ".binpic")
    arguments.append ("-u")
    arguments.append ("huzzah32:esp32")
    return (commande, arguments)
  }

  //································································································

  fileprivate func transférerParFTP () {
    self.mImageSuccessTransfererEnFTP?.image = NSImage (named: "NSSmartBadgeTemplate")
    let (command, arguments) = self.commandeTransférerParFTP ()
    self.runCancelableCommand (command, arguments, alertTitle: "Transfert par FTP") { (_ result : Int32) in
      if result == 0 {
        appendSuccessString ("Succès\n")
        self.mImageSuccessTransfererEnFTP?.image = NSImage (named: "NSStatusAvailable")
      }else{
        appendErrorString ("Échec (erreur \(result))\n")
        self.mImageSuccessTransfererEnFTP?.image = NSImage (named: "NSStatusUnavailable")
      }
    }
  }

  //································································································

  @IBAction func transférerParFtpAction (_ inSender : Any?) {
    self.effacerAvantOperations () ;
    var success = true
    self.compilerCroquisArduino (&success)
    if success {
      self.transformerElfEnBin (&success)
    }
    if success {
      self.transformerEnBinPic (&success)
    }
    if success {
      self.transférerParFTP ()
    }
  }

  //································································································

  @IBAction func effacerFichiersProductionAction (_ inSender : Any?) {
    self.effacerAvantOperations ()
    if let documentDirectory = self.fileURL?.deletingLastPathComponent ().path {
      let buildDir = documentDirectory + "/" + ARDUINO_BUILD_DIR
      try? FileManager.default.removeItem (atPath: buildDir)
    }
  }

  //································································································

}

//——————————————————————————————————————————————————————————————————————————————————————————————————
