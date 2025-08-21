//
//  ContentView.swift
//  Trans-Fer
//
//  Created by Pierre Molinaro on 16/08/2025.
//
//--------------------------------------------------------------------------------------------------

import SwiftUI

//--------------------------------------------------------------------------------------------------

let okStatusImage = NSImage (named: NSImage.Name (NSImage.statusAvailableName))!
//let warningStatusImage = NSImage (named: NSImage.Name (NSImage.statusPartiallyAvailableName))!
let errorStatusImage = NSImage (named: NSImage.Name (NSImage.statusUnavailableName))!
let unknownStatusImage = NSImage (named: NSImage.Name (NSImage.statusNoneName))!
let workingStatusImage = NSImage (named: NSImage.Name (NSImage.smartBadgeTemplateName))!

//--------------------------------------------------------------------------------------------------

struct Document_TransfertPIC_View : View {

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  init (document inDocument : Binding <Document_TransfertPIC>) {
    self._mDocument = inDocument
    self.mFileURL = nil
  }

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  init (document inDocument : Binding <Document_TransfertPIC>,
        fileURL inFileURL : URL?) {
    self.mFileURL = inFileURL
    self._mDocument = inDocument
  }

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  @Binding private var mDocument : Document_TransfertPIC
  private let mFileURL : URL?
  @State private var mStep1StatusImage = unknownStatusImage
  @State private var mStep2StatusImage = unknownStatusImage
  @State private var mStep3StatusImage = unknownStatusImage
  @State private var mStep4StatusImage = unknownStatusImage
  @State private var mStep5StatusImage = unknownStatusImage

  @State private var mTransfertParFTP : TransfertParFTP? = nil
  @State private var mShowTransfertSheet = false

  private var mTextLogger = TextLogger ()

//  @State private var mString = "Hello"

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  var body : some View {
    VStack {
//      TextField ("Exemple", text: self.$mString)
      HStack {
        Image (nsImage : NSImage (named: "TransfertPIC")!)
        GroupBox (label: Text ("Données du document")) {
          Form {
            TextField ("Nom du source", text: self.$mDocument.mNomFirmware)
            TextField ("Nom de l'updater", text: self.$mDocument.mNomUpdater)
            TextField ("Nom du firmware", text: self.$mDocument.mSignature)
            TextField ("Adresse CAN des PICs", text: self.$mDocument.mAdressesCAN)
            Toggle ("Optimisation de la compilation Piccolo", isOn: self.$mDocument.mOptimisation)
          }
        }
      }
      GroupBox (label: Text("Opérations")) {
        Button ("Supprimer fichiers produits") { self.supprimerFichiersProduits () }
        Divider ()
        HStack {
          Text("1︎⃣")
          Button ("Compiler le source Piccolo " + (self.mDocument.mOptimisation ? "(avec optimisation)" : "(sans optimisation)")) {
            self.step1CompilerSourcePiccolo ()
          }
          .frame (width: 350)
          Image (nsImage : self.mStep1StatusImage)
        }
        HStack {
          Text("2︎⃣")
          Button ("Transformer en fichier data Piccolo") {
            self.step2TransformerEnFichierDataPiccolo()
          }
          .frame (width: 350)
          Image (nsImage : self.mStep2StatusImage)
        }
        HStack {
          Text("3︎⃣")
          Button ("Compiler l'updater") { self.step3CompilerUpdater () }
          .frame (width: 350)
          Image (nsImage : self.mStep3StatusImage)
        }
        HStack {
          Text("4︎⃣")
          Button ("Transformer en fichier binpic") { self.step4TransformerEnFichierBINPIC () }
          .frame (width: 350)
          Image (nsImage : self.mStep4StatusImage)
        }
        HStack {
          Text("5︎⃣")
          Button ("Transférer par FTP") { self.step5TransfererParFTP () }
          .frame (width: 350)
          Image (nsImage : self.mStep5StatusImage)
        }
      }
      TextLoggerView (self.mTextLogger)
    }.padding (12).frame (height: 500)
    .sheet (
      isPresented: $mShowTransfertSheet
    ) {
      VStack {
        Text ("Transfert par FTP")
        Button ("Arrêter") { self.terminaisonAvecErreurTransfertParFTP () }
      }.padding (12)
    }
  }

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  private func supprimerFichiersProduits () {
    self.effacerAvantOperations ()
    if let documentDirectory = self.mFileURL?.deletingLastPathComponent ().path {
      try? FileManager.default.removeItem (atPath: documentDirectory + "/" + self.mDocument.mNomFirmware + ".asm")
      try? FileManager.default.removeItem (atPath: documentDirectory + "/" + self.mDocument.mNomFirmware + ".hex")
      try? FileManager.default.removeItem (atPath: documentDirectory + "/" + self.mDocument.mNomFirmware + ".hex.piccolo")
      try? FileManager.default.removeItem (atPath: documentDirectory + "/" + self.mDocument.mNomFirmware + ".list")
      try? FileManager.default.removeItem (atPath: documentDirectory + "/" + self.mDocument.mNomUpdater + ".hex")
      try? FileManager.default.removeItem (atPath: documentDirectory + "/" + self.mDocument.mNomUpdater + ".asm")
      try? FileManager.default.removeItem (atPath: documentDirectory + "/" + self.mDocument.mNomUpdater + ".list")
      try? FileManager.default.removeItem (atPath: documentDirectory + "/" + self.mDocument.mSignature + ".binpic")
    }
  }

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  private func effacerAvantOperations () {
    self.mTextLogger.removeContent ()
    self.mStep1StatusImage = unknownStatusImage
    self.mStep2StatusImage = unknownStatusImage
    self.mStep3StatusImage = unknownStatusImage
    self.mStep4StatusImage = unknownStatusImage
    self.mStep5StatusImage = unknownStatusImage
  }

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  private func step1CompilerSourcePiccolo () {
    self.effacerAvantOperations ()
    var success = true
    self.compilerCodePiccolo (&success)
  }

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  private func step2TransformerEnFichierDataPiccolo () {
    self.effacerAvantOperations ()
    var success = true
    self.compilerCodePiccolo (&success)
    if success {
      self.transformerEnFichierDataPiccolo (&success)
    }
  }

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  private func transformerEnFichierDataPiccolo (_ ioSuccess : inout Bool) {
    self.mStep2StatusImage = workingStatusImage
    let result = self.conversionEnPiccoloData (self.mDocument.mNomFirmware + ".hex")
    if result == 0 {
      self.mTextLogger.appendSuccessString ("Succès\n")
      self.mStep2StatusImage = okStatusImage
    }else{
      self.mTextLogger.appendErrorString ("Échec (erreur \(result))\n")
      self.mStep2StatusImage = errorStatusImage
      ioSuccess = false
    }
  }

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  private func conversionEnPiccoloData (_ inFichierHex : String) -> Int {
    self.mTextLogger.appendCommandString ("Transformer en Piccolo Data\n")
    let documentDir = self.mFileURL?.deletingLastPathComponent ().path ?? "?"
  //--- Lire le fichier hex
    let data = try! Data (contentsOf: URL (fileURLWithPath: documentDir + "/" + inFichierHex))
  //--- Itérer sur les lignes
    var enDébutDeLigne = true
    var premierCaractère = true
    var éléments = [UInt8] ()
    var code = [UInt16 : UInt8] ()
    var dernièreAdresse = UInt16 (0)
    var adresseExtension = UInt16 (0)
    for byte in [UInt8] (data) {
    //--- Décomposer la ligne
      if enDébutDeLigne {
        if byte ==  ASCII.colon.rawValue {
          enDébutDeLigne = false
        }else{
          self.mTextLogger.appendErrorString ("  Erreur, la ligne ne commence pas par \":\"\n")
          return 1
        }
      }else if (byte >= ASCII.zero.rawValue) && (byte <= ASCII.nine.rawValue) {
        let v = byte - ASCII.zero.rawValue
        if premierCaractère {
          éléments.append (v)
        }else{
          éléments [éléments.count - 1] <<= 4 ;
          éléments [éléments.count - 1] |= v ;
        }
        premierCaractère = !premierCaractère
      }else if (byte >= ASCII.A.rawValue) && (byte <= ASCII.F.rawValue) {
        let v = (byte - ASCII.A.rawValue) + 10
        if premierCaractère {
          éléments.append (v)
        }else{
          éléments [éléments.count - 1] <<= 4 ;
          éléments [éléments.count - 1] |= v ;
        }
        premierCaractère = !premierCaractère
      }else if (byte >= ASCII.a.rawValue) && (byte <= ASCII.f.rawValue) {
        let v = (byte - ASCII.a.rawValue) + 10
        if premierCaractère {
          éléments.append (v)
        }else{
          éléments [éléments.count - 1] <<= 4 ;
          éléments [éléments.count - 1] |= v ;
        }
        premierCaractère = !premierCaractère
      }else if byte == ASCII.lineFeed.rawValue {
        if !premierCaractère {
          self.mTextLogger.appendErrorString ("  Erreur de phase sur caractère\n")
          return 2
        }
      //--- Vérifier la somme de contrôle
        var somme : UInt8 = 0
        for v in éléments {
          somme &+= v
        }
        if somme != 0 {
          self.mTextLogger.appendErrorString ("  Erreur de somme de contrôle (\(somme))\n")
          return 3
        }
      //---
        let nombreOctets = UInt16 (éléments [0])
        let adresseDébut = (UInt16 (éléments [1]) << 8) | UInt16 (éléments [2])
        let type = éléments [3]
        if (type == 0) && (adresseExtension == 0) { // Données
          for i in 0 ..< nombreOctets {
            code [adresseDébut + i] = éléments [4 + Int (i)]
          }
          dernièreAdresse = max (dernièreAdresse, adresseDébut + nombreOctets - 1)
        }else if type == 4 { // Extension
          adresseExtension = (UInt16 (éléments [5]) << 8) | UInt16 (éléments [4])
        }
      //---
        éléments.removeAll ()
        enDébutDeLigne = true
      }else{
        self.mTextLogger.appendErrorString ("  Erreur, caractère inconnu\n")
        return 4
      }
    }
  //--- Construire la liste des blocs de 64 octets
    var listBlocs = [Bloc] ()
    var buffer = [UInt16] ()
    var premierOctet = true
    for adresse in 0 ... dernièreAdresse {
      let data = UInt16 (code [adresse, default: 0xFF])
      if premierOctet {
        buffer.append (data)
      }else{
        buffer [buffer.count - 1] |= data << 8
        if buffer.count == 32 {
          let bloc = Bloc (mAdresseDébut: (adresse >> 6) << 6, mDonnées: buffer)
          if !bloc.contientQueDesUns {
            listBlocs.append (bloc)
          }
          buffer.removeAll ()
        }
      }
      premierOctet = !premierOctet
    }
  //--- Complèter le dernier bloc
    if buffer.count > 0 {
      while buffer.count < 32 {
        buffer.append (0xFFFF)
      }
      let bloc = Bloc (mAdresseDébut: (dernièreAdresse >> 6) << 6, mDonnées: buffer)
      if !bloc.contientQueDesUns {
        listBlocs.append (bloc)
      }
    }
    self.mTextLogger.appendMessageString ("  \(listBlocs.count) blocs\n")
  //--- Engendrer le fichier Piccolo
    var s = "data16 bootloaderData {\n"
    s += "#--- Bloc count\n"
    s += "  \(listBlocs.count)"
    for bloc in listBlocs.reversed () {
      s += ",\n#--- Bloc à l'adresse 0x\(String (bloc.mAdresseDébut, radix: 16, uppercase: true))\n"
      s += "  0x\(String (bloc.mAdresseDébut >> 6, radix: 16, uppercase: true))"
      for i in 0 ..< 32 {
        s += ","
        if (i % 8) == 0 {
          s += "\n "
        }
        s += " 0x\(String (bloc.mDonnées [i], radix: 16, uppercase: true))"
      }
    }
    s += "\n}\n"
  //--- Écrire le fichier
    let url = URL (fileURLWithPath: documentDir + "/" + inFichierHex).appendingPathExtension ("piccolo")
    try! s.write (to: url, atomically: true, encoding: .utf8)
  //---
    return 0
  }

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  private func step3CompilerUpdater () {
    self.effacerAvantOperations ()
    var success = true
    self.compilerCodePiccolo (&success)
    if success {
      self.transformerEnFichierDataPiccolo (&success)
    }
    if success {
      self.compilerUpdater (&success)
    }
  }

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  private func step4TransformerEnFichierBINPIC () {
    self.effacerAvantOperations ()
    var success = true
    self.compilerCodePiccolo (&success)
    if success {
      self.transformerEnFichierDataPiccolo (&success)
    }
    if success {
      self.compilerUpdater (&success)
    }
    if success {
      self.transformerEnBinPic (&success)
    }
  }

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  private func step5TransfererParFTP () {
    self.effacerAvantOperations ()
    var success = true
    self.compilerCodePiccolo (&success)
    if success {
      self.transformerEnFichierDataPiccolo (&success)
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

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  private func compilerCodePiccolo (_ ioSuccess : inout Bool) {
    self.mStep1StatusImage = workingStatusImage
    let (command, arguments) = self.commandeCompilationSourcePiccolo ()
    let result = self.runCommand (command, arguments)
    if result == 0 {
      self.mTextLogger.appendSuccessString ("Succès\n")
      self.mStep1StatusImage = okStatusImage
    }else{
      self.mTextLogger.appendErrorString ("Échec (erreur \(result))\n")
      self.mStep1StatusImage = errorStatusImage
      ioSuccess = false
    }
  }

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  private func commandeCompilationSourcePiccolo () -> (String, [String]) {
    let commande = (UserDefaults.standard.string (forKey: PREFS_PICCOLO_APP) ?? "?") + "/Contents/Resources/piccolo"
    var arguments = [String] ()
    arguments.append ("--Werror")
    arguments.append ("-S")
    if self.mDocument.mOptimisation {
      arguments.append ("-O")
    }
    arguments.append ("-L")
    arguments.append ("--no-color")
    arguments.append (self.mDocument.mNomFirmware + ".piccolo")
    return (commande, arguments)
  }

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  private func compilerUpdater (_ ioSuccess : inout Bool) {
    self.mStep3StatusImage = workingStatusImage
    let (command, arguments) = self.commandeCompilationUpdaterPiccolo ()
    let result = self.runCommand (command, arguments)
    if result == 0 {
      self.mTextLogger.appendSuccessString ("Succès\n")
      self.mStep3StatusImage = okStatusImage
    }else{
      self.mTextLogger.appendErrorString ("Échec (erreur \(result))\n")
      self.mStep3StatusImage = errorStatusImage
      ioSuccess = false
    }
  }

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  private func commandeCompilationUpdaterPiccolo () -> (String, [String]) {
    let commande = (UserDefaults.standard.string (forKey: PREFS_PICCOLO_APP) ?? "?") + "/Contents/Resources/piccolo"
    var arguments = [String] ()
    arguments.append ("--Werror")
    arguments.append ("-S")
    arguments.append ("-O")
    arguments.append ("-L")
    arguments.append ("--no-color")
    arguments.append (self.mDocument.mNomUpdater + ".piccolo")
    return (commande, arguments)
  }

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  private func transformerEnBinPic (_ ioSuccess : inout Bool) {
    self.mStep4StatusImage = workingStatusImage
    let fichierUpdaterHex = self.mDocument.mNomUpdater + ".hex"
    let signatureFirmware = self.mDocument.mSignature
    let adressesPIC = self.mDocument.mAdressesCAN.components (separatedBy: " ").joined (separator: "")
    var (array, result) = parsePicsCible (adressesPIC)
    if result == 0 {
      result = self.construireFichierBinaireDistribution (fichierUpdaterHex, array, signatureFirmware)
    }
    if result == 0 {
      self.mTextLogger.appendSuccessString ("Succès\n")
      self.mStep4StatusImage = okStatusImage
    }else{
      self.mTextLogger.appendErrorString ("Échec (erreur \(result))\n")
      self.mStep4StatusImage = errorStatusImage
      ioSuccess = false
    }
  }

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  private func parsePicsCible (_ inString : String) -> ([UInt8], Int) {
    var result = [UInt8] ()
    let components = inString.components (separatedBy: ",")
    for v in components {
      let components2 = v.components (separatedBy: ":")
      if components2.count == 1 {
        if let adresse = UInt8 (components2 [0]) {
          result.append (adresse)
        }else{
          self.mTextLogger.appendErrorString ("Erreur, \(v) n'est pas un nombre entre 0 et 255\n")
          return ([], 6)
        }
      }else if components2.count == 2 {
        if let adresseDébut = UInt8 (components2 [0]), let adresseFin = UInt8 (components2 [1]), adresseDébut < adresseFin {
          var adresse = adresseDébut
          while (adresse <= adresseFin) {
            result.append (adresse)
            adresse += 1
          }
        }else{
          self.mTextLogger.appendErrorString ("Erreur, \(v) n'est pas un intervalle valide\n")
          return ([], 7)
        }
      }else{
        self.mTextLogger.appendErrorString ("Erreur, \(v) n'est pas invalide\n")
        return ([], 8)
      }
    }
    return (result, 0)
  }

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  private func construireFichierBinaireDistribution (_ SOURCE_PICCOLO_UPDATER : String,
                                             _ PICS_CIBLE : [UInt8],
                                             _ NOM_PIC_FIRMWARE : String) -> Int {
    self.mTextLogger.appendCommandString ("③ Construire le fichier binaire de la distribution\n")
    var s = "PICs cibles :"
    for v in PICS_CIBLE {
      s += " \(v)"
    }
    self.mTextLogger.appendMessageString (s + "\n")
  //-------------------------------------------------------- Read HEX file
    let documentDir = self.mFileURL?.deletingLastPathComponent ().path ?? "?"
    let hexString = try! String (contentsOf: URL (fileURLWithPath: documentDir + "/" + SOURCE_PICCOLO_UPDATER))
    let hexLines = hexString.components (separatedBy: "\n")
    var codeDictionary = [UInt16 : UInt8] ()
    var adresseBase : UInt32? = nil
    for line in hexLines {
      if line != "" {
        var data = line.data (using: .ascii)!
        let b = data.remove (at: 0)
        if b != ASCII.colon.rawValue {
          self.mTextLogger.appendErrorString ("Erreur, une ligne ne commence pas par ':'\n")
          return 2
        }
        var ok = true
        let longueur = UInt16 (parseByte (&data, &ok))
        let adresse : UInt16 = parseUInt16 (&data, &ok)
        let code : UInt8 = parseByte (&data, &ok)
        if code == 4 {
           adresseBase = UInt32 (adresse)
        }else if code == 0 {
          for i in 0 ..< longueur {
            let byte = parseByte (&data, &ok)
            codeDictionary [adresse + i] = byte
          }
        }
        if !ok {
          self.mTextLogger.appendErrorString ("Erreur, le caractère n'est pas un chiffre hex.\n")
          return 1
        }
      }
    }
  //--- Préparer la génération du fichier
    var contents = Data ()
  //--- Écrire l'adresse de base
    let keys = codeDictionary.keys.sorted ()
    let minAddress = keys [0]
    let adresseDébut = adresseBase! + UInt32 (minAddress)
    self.mTextLogger.appendMessageString ("Adresse de flashage : 0x" + String (adresseDébut, radix: 16, uppercase: true) + "\n")
    contents.append (UInt8 ((adresseDébut >> 14) & 0xFF))
    contents.append (UInt8 ((adresseDébut >>  6) & 0xFF))
  //--- Écrire la description des adresses des PICs destinataires
    var adressesOrdonnées = PICS_CIBLE.sorted ()
    self.mTextLogger.appendMessageString ("Adresses des PICs destinataires : \(adressesOrdonnées)\n")
    var adresseCourante = adressesOrdonnées.remove (at: 0)
    var nombreAdressesConsécutives : UInt8 = 1
    for adressePIC in adressesOrdonnées {
      if adressePIC == (adresseCourante + nombreAdressesConsécutives - 1) {
        self.mTextLogger.appendErrorString ("Erreur, doublon dans la liste PICS_CIBLE : \(adressePIC) apparaît plusieurs fois\n")
        return 3
      }else if adressePIC == (adresseCourante + nombreAdressesConsécutives) {
        nombreAdressesConsécutives += 1
      }else{
        contents.append (nombreAdressesConsécutives)
        contents.append (adresseCourante)
        adresseCourante = adressePIC
        nombreAdressesConsécutives = 1
      }
    }
    contents.append (nombreAdressesConsécutives)
    contents.append (adresseCourante)
    contents.append (0) // Marque de fin
  //--- Écrire le code des PICs
    let lastAddress = keys.last!
    for address in minAddress ... lastAddress {
      let byte = codeDictionary [address] ?? 0xFF
      contents.append (byte)
    }
  //--- Calculer le CRC
    var crc = UInt32.max
    for byte in contents {
      accumulateByteWithLookUpTable (byte: byte, crc: &crc)
    }
    self.mTextLogger.appendMessageString ("CRC: 0x" + String (crc, radix: 16, uppercase: true) + "\n")
    contents.append (UInt8 ((crc >> 24) & 0xFF))
    contents.append (UInt8 ((crc >> 16) & 0xFF))
    contents.append (UInt8 ((crc >>  8) & 0xFF))
    contents.append (UInt8 ((crc >>  0) & 0xFF))
  //-------------------------------------------------------- Check CRC
    crc = UInt32.max
    for byte in contents {
      accumulateByteWithLookUpTable (byte: byte, crc: &crc)
    }
    self.mTextLogger.appendMessageString ("Vérification CRC: \(String (crc, radix: 16, uppercase: true)) (\((crc == 0) ? "ok" : "erreur"))\n") // Doit être 0
    if crc != 0 {
      return 4
    }
  //--- Écrire le fichier
    try! contents.write (to: URL (fileURLWithPath: documentDir + "/" + NOM_PIC_FIRMWARE + ".binpic"))
  //---
    return 0 // Ok
  }

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  private func transférerParFTP () {
    self.mStep5StatusImage = workingStatusImage
    let (command, arguments) = self.commandeTransférerParFTP ()
    let transfertParFTP = TransfertParFTP ()
    self.mTransfertParFTP = transfertParFTP
    transfertParFTP.runCancelableCommand (
      command: command,
      arguments: arguments,
      processCurrentDirectoryPath: self.mFileURL?.deletingLastPathComponent().path ?? "?",
      alertState: self.$mShowTransfertSheet,
      commandStringHandler: { self.mTextLogger.appendCommandString ($0) },
      messageStringHandler: { self.mTextLogger.appendMessageString ($0) },
      terminationSuccessHandler: { self.terminaisonAvecSuccessTransfertParFTP () }
    )
  }

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  private func terminaisonAvecSuccessTransfertParFTP () {
    self.mShowTransfertSheet = false
    self.mTextLogger.appendSuccessString ("Succès\n")
    self.mStep5StatusImage = okStatusImage
    self.mTransfertParFTP = nil
  }

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  private func terminaisonAvecErreurTransfertParFTP () {
    self.mShowTransfertSheet = false
    if let transfert = self.mTransfertParFTP {
      self.mTextLogger.appendErrorString ("Échec (erreur \(transfert.result))\n")
      self.mStep5StatusImage = errorStatusImage
      self.mTransfertParFTP = nil
    }
  }

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  private func commandeTransférerParFTP () -> (String, [String]) {
    let commande = "/usr/bin/curl"
    var arguments = [String] ()
    arguments.append ("-L") // Follow redirections
    arguments.append ("-s") // Silent mode, do not show download progress
 //   arguments.append ("-k") // Turn off curl's verification of certificate
    arguments.append ("-T")
    arguments.append (self.mDocument.mSignature + ".binpic")
    let ip = UserDefaults.standard.string (forKey: PREFS_ADRESSE_IP_CARTE_MEZZANINE) ?? "?"
    arguments.append ("ftp://\(ip)/" + self.mDocument.mSignature + ".binpic")
    arguments.append ("-u")
    arguments.append ("huzzah32:esp32")
    return (commande, arguments)
  }

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  private func runCommand (_ inCommand : String, _ inArguments : [String]) -> Int32 {
  //--- Command String
    var str = inCommand
    for s in inArguments {
      str += " " + s
    }
    str += "\n"
    self.mTextLogger.appendCommandString (str)
    if let documentDir = self.mFileURL?.deletingLastPathComponent ().path {
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
            DispatchQueue.main.async { self.mTextLogger.appendMessageString (str) }
            data = Data ()
          }
          newData = stdoutHandle.availableData
        }
      }
      task.launch ()
    //--- Task completed
      task.waitUntilExit ()
      let status = task.terminationStatus
      return status
    }else{
      self.mTextLogger.appendErrorString ("Cannot run, the document is not saved\n")
      return 1
    }
  }

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

}

//--------------------------------------------------------------------------------------------------

fileprivate struct Bloc {

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  let mAdresseDébut : UInt16 // Multiple de 64
  let mDonnées : [UInt16] // Contient toujours 32 éléments (soit 64 octets)

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  var contientQueDesUns : Bool {
    for data in self.mDonnées {
      if data != 0xFFFF {
        return false
      }
    }
    return true
  }

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
}

//--------------------------------------------------------------------------------------------------

#Preview {
  Document_TransfertPIC_View (document: .constant (Document_TransfertPIC ()))
}

//--------------------------------------------------------------------------------------------------
