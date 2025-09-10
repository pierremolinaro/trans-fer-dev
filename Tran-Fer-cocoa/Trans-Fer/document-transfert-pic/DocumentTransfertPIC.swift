//
//  DocumentTransfertPIC.swift
//  Trans-Fer
//
//  Created by Pierre Molinaro on 09/02/2022.
//
//——————————————————————————————————————————————————————————————————————————————————————————————————

import AppKit

//——————————————————————————————————————————————————————————————————————————————————————————————————

@MainActor @objc(DocumentTransfertPIC) class DocumentTransfertPIC : NSDocument {

  //································································································

  @IBOutlet var mNomFirmwareTextField : NSTextField? = nil
  @IBOutlet var mNomUpdaterTextField : NSTextField? = nil
  @IBOutlet var mOptimisationCheckbox : NSButton? = nil
  @IBOutlet var mSignatureTextField : NSTextField? = nil
  @IBOutlet var mAdressesTextField : NSTextField? = nil

  @IBOutlet var mCommandeCompilationButton : NSButton? = nil
  @IBOutlet var mImageSuccessCompilation : NSImageView? = nil

  @IBOutlet var mCommandeCompilationUpdaterButton : NSButton? = nil
  @IBOutlet var mImageSuccessCompilationUpdater : NSImageView? = nil

  @IBOutlet var mCommandeTransformerEnDataPiccoloButton : NSButton? = nil
  @IBOutlet var mImageSuccessTransformationEnPiccoloData : NSImageView? = nil

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

  @objc private dynamic var mNomFirmware : String = "" {
    didSet {
      self.undoManager?.registerUndo (withTarget: self) {
        $0.willChangeValue (forKey: "mNomFirmware")
        $0.mNomFirmware = oldValue
        $0.didChangeValue (forKey: "mNomFirmware")
      }
    }
  }

  //································································································

  @objc private dynamic var mNomUpdater : String = "" {
    didSet {
      self.undoManager?.registerUndo (withTarget: self) {
        $0.willChangeValue (forKey: "mNomUpdater")
        $0.mNomUpdater = oldValue
        $0.didChangeValue (forKey: "mNomUpdater")
      }
    }
  }

  //································································································

  @objc private dynamic var mOptimisation : Bool = true {
    didSet {
      self.undoManager?.registerUndo (withTarget: self) {
        $0.willChangeValue (forKey: "mOptimisation")
        $0.mOptimisation = oldValue
        $0.didChangeValue (forKey: "mOptimisation")
      }
    }
  }

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
    return NSNib.Name ("DocumentTransfertPIC")
  }

  //································································································

  override func data (ofType typeName: String) throws -> Data {
    var s = self.mNomFirmware + "\n"
    s += self.mNomUpdater + "\n"
    s += (self.mOptimisation ? "1" : "0") + "\n"
    s += self.mSignature + "\n"
    s += self.mAdressesCAN + "\n"
    let data = s.data (using: .utf8)!
    return data
  }

  //································································································

  nonisolated override func read (from inData : Data, ofType typeName: String) throws {
    DispatchQueue.main.async {
      self.undoManager?.disableUndoRegistration ()
        let s = String (data: inData, encoding: .utf8)!
        let components = s.components (separatedBy: "\n")
        self.mNomFirmware = components [0]
        self.mNomUpdater = components [1]
        self.mOptimisation = components [2] == "1"
        self.mSignature = components [3]
        self.mAdressesCAN = components [4]
      self.undoManager?.enableUndoRegistration ()
    }
  }

  //································································································

  override func windowControllerDidLoadNib (_ windowController : NSWindowController) {
    self.mNomFirmwareTextField?.bind (
      .value,
      to: self,
      withKeyPath: "mNomFirmware",
      options: [NSBindingOption.continuouslyUpdatesValue : true]
    )
    self.mNomUpdaterTextField?.bind (
      .value,
      to: self,
      withKeyPath: "mNomUpdater",
      options: [NSBindingOption.continuouslyUpdatesValue : true]
    )
    self.mOptimisationCheckbox?.bind (
      .value,
      to: self,
      withKeyPath: "mOptimisation",
      options: nil
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
                             _ inCallBack : @escaping @Sendable (_ inStatus : Int32) -> Void) {
  //--- Command String
    var str = "+ " + cmd
    for s in args {
      str += " " + s
    }
    appendCommandString (str + "\n")
  //--- Run Command
    if let documentDir = self.fileURL?.deletingLastPathComponent ().path {
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

  func runCommand (_ inCommand : String, _ inArguments : [String]) -> Int32 {
  //--- Command String
    var str = inCommand
    for s in inArguments {
      str += " " + s
    }
    str += "\n"
    appendCommandString (str)
    if let documentDir = self.fileURL?.deletingLastPathComponent ().path {
    //--- Run Command
      let task = Process ()
      task.launchPath = inCommand
      task.arguments = inArguments
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
      appendErrorString ("Cannot run, the document is not saved\n")
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
    self.mImageSuccessTransformationEnPiccoloData?.image = nil
    self.mImageSuccessCompilationUpdater?.image = nil
    self.mImageSuccessTransformationEnBinPic?.image = nil
    self.mImageSuccessTransfererEnFTP?.image = nil
  }

  //································································································

  private func commandeCompilationSourcePiccolo () -> (String, [String]) {
    let commande = (UserDefaults.standard.string (forKey: PREFS_PICCOLO_APP) ?? "?") + "/Contents/Resources/piccolo"
    var arguments = [String] ()
    arguments.append ("--Werror")
    arguments.append ("-S")
    if self.mOptimisation {
      arguments.append ("-O")
    }
    arguments.append ("-L")
    arguments.append ("--no-color")
    arguments.append (self.mNomFirmware + ".piccolo")
    return (commande, arguments)
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
    arguments.append (self.mNomUpdater + ".piccolo")
    return (commande, arguments)
  }

  //································································································

  fileprivate func compilerCodePiccolo (_ ioSuccess : inout Bool) {
    self.mImageSuccessCompilation?.image = NSImage (named: "NSSmartBadgeTemplate")
    let (command, arguments) = self.commandeCompilationSourcePiccolo ()
    let result = self.runCommand (command, arguments)
    if result == 0 {
      appendSuccessString ("Succès\n")
      self.mImageSuccessCompilation?.image = NSImage (named: "NSStatusAvailable")
    }else{
      appendErrorString ("Échec (erreur \(result))\n")
      self.mImageSuccessCompilation?.image = NSImage (named: "NSStatusUnavailable")
      ioSuccess = false
    }
  }

  //································································································

  fileprivate func compilerUpdater (_ ioSuccess : inout Bool) {
    self.mImageSuccessCompilationUpdater?.image = NSImage (named: "NSSmartBadgeTemplate")
    let (command, arguments) = self.commandeCompîlationUpdaterPiccolo ()
    let result = self.runCommand (command, arguments)
    if result == 0 {
      appendSuccessString ("Succès\n")
      self.mImageSuccessCompilationUpdater?.image = NSImage (named: "NSStatusAvailable")
    }else{
      appendErrorString ("Échec (erreur \(result))\n")
      self.mImageSuccessCompilationUpdater?.image = NSImage (named: "NSStatusUnavailable")
      ioSuccess = false
    }
  }

  //································································································

  fileprivate func transformerEnDataPiccolo (_ ioSuccess : inout Bool) {
    self.mImageSuccessTransformationEnPiccoloData?.image = NSImage (named: "NSSmartBadgeTemplate")
    let result = self.conversionEnPiccoloData (self.mNomFirmware + ".hex")
    if result == 0 {
      appendSuccessString ("Succès\n")
      self.mImageSuccessTransformationEnPiccoloData?.image = NSImage (named: "NSStatusAvailable")
    }else{
      appendErrorString ("Échec (erreur \(result))\n")
      self.mImageSuccessTransformationEnPiccoloData?.image = NSImage (named: "NSStatusUnavailable")
      ioSuccess = false
    }
  }

  //································································································

  @IBAction func compileAction (_ inSender : Any?) {
    self.effacerAvantOperations () ;
    var success = true
    compilerCodePiccolo (&success)
  }

  //································································································

  @IBAction func transformToPiccoloDataAction (_ inSender : Any?) {
    self.effacerAvantOperations () ;
    var success = true
    self.compilerCodePiccolo (&success)
    if success {
      self.transformerEnDataPiccolo (&success)
    }
  }

  //································································································

  @IBAction func compilerUpdaterAction (_ inSender : Any?) {
    self.effacerAvantOperations () ;
    var success = true
    self.compilerCodePiccolo (&success)
    if success {
      self.transformerEnDataPiccolo (&success)
    }
    if success {
      self.compilerUpdater (&success)
    }
  }

  //································································································

  private func commandTransformerEnBinPic () -> (String, [String]) {
    let commande = Bundle.main.resourcePath! + "/HexToBinPIC"
    var arguments = [String] ()
    arguments.append (self.mNomUpdater + ".hex")
    arguments.append (self.mSignature)
    let c = self.mAdressesCAN.components (separatedBy: " ")
    arguments.append (c.joined (separator: ""))
    return (commande, arguments)
  }

  //································································································

  fileprivate func transformerEnBinPic (_ ioSuccess : inout Bool) {
    self.mImageSuccessTransformationEnBinPic?.image = NSImage (named: "NSSmartBadgeTemplate")
    let fichierUpdaterHex = self.mNomUpdater + ".hex"
    let signatureFirmware = self.mSignature
    let adressesPIC = self.mAdressesCAN.components (separatedBy: " ").joined (separator: "")
    var (array, result) = parsePicsCible (adressesPIC)
    if result == 0 {
      result = self.construireFichierBinaireDistribution (fichierUpdaterHex, array, signatureFirmware)
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
    self.compilerCodePiccolo (&success)
    if success {
      self.transformerEnDataPiccolo (&success)
    }
    if success {
      self.compilerUpdater (&success)
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
    arguments.append (self.mSignature + ".binpic")
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
      DispatchQueue.main.async {
        if result == 0 {
          appendSuccessString ("Succès\n")
          self.mImageSuccessTransfererEnFTP?.image = NSImage (named: "NSStatusAvailable")
        }else{
          appendErrorString ("Échec (erreur \(result))\n")
          self.mImageSuccessTransfererEnFTP?.image = NSImage (named: "NSStatusUnavailable")
        }
      }
    }
  }

  //································································································

  @IBAction func transférerParFtpAction (_ inSender : Any?) {
    self.effacerAvantOperations () ;
    var success = true
    self.compilerCodePiccolo (&success)
    if success {
      self.transformerEnDataPiccolo (&success)
    }
    if success {
      self.compilerUpdater (&success)
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
      try? FileManager.default.removeItem (atPath: documentDirectory + "/" + self.mNomFirmware + ".asm")
      try? FileManager.default.removeItem (atPath: documentDirectory + "/" + self.mNomFirmware + ".hex")
      try? FileManager.default.removeItem (atPath: documentDirectory + "/" + self.mNomFirmware + ".hex.piccolo")
      try? FileManager.default.removeItem (atPath: documentDirectory + "/" + self.mNomFirmware + ".list")
      try? FileManager.default.removeItem (atPath: documentDirectory + "/" + self.mNomUpdater + ".hex")
      try? FileManager.default.removeItem (atPath: documentDirectory + "/" + self.mNomUpdater + ".asm")
      try? FileManager.default.removeItem (atPath: documentDirectory + "/" + self.mNomUpdater + ".list")
      try? FileManager.default.removeItem (atPath: documentDirectory + "/" + self.mSignature + ".binpic")
    }
  }

  //································································································

}

//——————————————————————————————————————————————————————————————————————————————————————————————————
