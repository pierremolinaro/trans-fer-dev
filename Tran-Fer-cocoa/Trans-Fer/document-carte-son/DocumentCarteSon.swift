//
//  DocumentCarteSon.swift
//  Trans-Fer
//
//  Created by Pierre Molinaro on 26/03/2022.
//
//——————————————————————————————————————————————————————————————————————————————————————————————————
// https://developer.apple.com/forums/thread/116723
//——————————————————————————————————————————————————————————————————————————————————————————————————

import AppKit
import Network

//——————————————————————————————————————————————————————————————————————————————————————————————————

let FENÊTRE_ENVOI = 2

//——————————————————————————————————————————————————————————————————————————————————————————————————
//   MODE TRANSFERT DES SONS
//——————————————————————————————————————————————————————————————————————————————————————————————————
// FORMAT DES TRAMES CAN VIA LA LAISON WIFI
// Une trame est codée sur 10 octets
//  - octet 0 : code du service
//  - octet 1 : longueur (entre 0 et 8)
//  - octets 2 à 9 : 8 octets de données (toujours 8, quelque soit la longueur effective)
//——————————————————————————————————————————————————————————————————————————————————————————————————
//  CODE DES SERVICES ET TRAMES ENVOYÉES VIA WIFI
//    0 à 15 -> requête de lecture vers une carte son (0x1EBFddss)
//   48 -> commande effacement secteur, ou calcul de CRC d'un son (0x772)
//--- Par encore implémentés
//   16 à 31 -> requête d'écriture vers une carte son (0x1E9Fddss)
//   32 à 47 -> commande écriture page son (0x76x)
//   49 -> jouer un son (0x770)
// La trame reçue a pour identificateur 01s ssss sss1
//——————————————————————————————————————————————————————————————————————————————————————————————————
//  CODE DES SERVICES ET TRAMES REÇUES VIA WIFI
//    0 à 15 -> réponse de lecture (0x13DFddss)
//   16 à 31 -> acquittement effacement secteur son, ou réponse calcul de CRC d'un son (0x74x)
//--- Par encore implémentés
//   16 à 31 -> réponse d'écriture (0x119Fddss)
//   31 à 47 -> acquittement écriture page son (0x75x)
// La trame envoyée a pour identificateur 01s ssss sss0
//——————————————————————————————————————————————————————————————————————————————————————————————————

struct Trame {
  let codeService : UInt8
  let données : [UInt8] // Max 8

  func be32 (atIndex inIndex : Int) -> UInt32 {
    var r = UInt32 (self.données [inIndex + 0])
    r <<= 8
    r |= UInt32 (self.données [inIndex + 1])
    r <<= 8
    r |= UInt32 (self.données [inIndex + 2])
    r <<= 8
    r |= UInt32 (self.données [inIndex + 3])
    return r
  }

  func be16 (atIndex inIndex : Int) -> UInt16 {
    var r = UInt16 (self.données [inIndex + 0])
    r <<= 8
    r |= UInt16 (self.données [inIndex + 1])
    return r
  }
}

//——————————————————————————————————————————————————————————————————————————————————————————————————

extension Double {

  var chaîneDuréeMS : String {
    let duréeMS = Int (self * 1000.0)
    var s = ""
    let minutes = duréeMS / 60_000
    if minutes > 0 {
      s += " \(minutes) min"
    }
    let secondes = (duréeMS % 60_000) / 1000
    if secondes > 0 {
      s += " \(secondes) s"
    }
    let millisecondes = duréeMS % 1000
    if millisecondes > 0 {
      s += " \(millisecondes) ms"
    }
    return s
  }

  var chaîneDuréeS : String {
    let duréeMS = Int (self)
    var s = ""
    let minutes = duréeMS / 60
    if minutes > 0 {
      s += " \(minutes) min"
    }
    let secondes = duréeMS % 60
    if secondes > 0 {
      s += " \(secondes) s"
    }
    return s
  }
}

//——————————————————————————————————————————————————————————————————————————————————————————————————

protocol ProtocoleOpérationCarteSon : AnyObject {

  func démarrer (tramesÀEnvoyer outTrames : inout [Trame])
  func réception (trameReçue inTrame : Trame, tramesÀEnvoyer outTrames : inout [Trame])

  func progression () -> (Int, Int, Bool) // (progression, total, terminé) si (0, 0) indéterminé
}

//——————————————————————————————————————————————————————————————————————————————————————————————————

@MainActor @objc(DocumentCarteSon) class DocumentCarteSon : NSDocument {

  //································································································

  @IBOutlet var mNuméroCarteSonPopUpButton : NSPopUpButton? = nil
  @IBOutlet var mTabViewCatalogue : NSTabView? = nil
  @IBOutlet var mAdresseCANCarteSonTextField : NSTextField? = nil
  @IBOutlet var mTableViewCatalogueDesSonsDuPIC : NSTableView? = nil
  @IBOutlet var mBoutonTelechargerLeSon10Bits : NSButton? = nil
  @IBOutlet var mCopierCataloguePICDansCatalogueDocument : NSButton? = nil
  @IBOutlet var mTableViewCatalogueDesSonsDuDocument : NSTableView? = nil
  @IBOutlet var mStatutFinDuCatalogueDesSonsDuDocumentTextField : NSTextField? = nil

  //································································································
  //  Panel de progression
  //································································································

  @IBOutlet var mPanelOperation : NSPanel? = nil
  @IBOutlet var mTitreOperation : NSTextField? = nil
  @IBOutlet var mIndicateurProgression : NSProgressIndicator? = nil
  @IBOutlet var mCommentaireProgression : NSTextField? = nil
  @IBOutlet var mBoutonAnnuler : NSButton? = nil

  //································································································

  @objc dynamic var mNumeroCarteSon : Int = 0 {
    didSet {
      if self.mNumeroCarteSon != oldValue {
        self.undoManager?.registerUndo (withTarget: self) {
          self.willChangeValue (forKey: "mNumeroCarteSon")
          $0.mNumeroCarteSon = oldValue
          self.didChangeValue (forKey: "mNumeroCarteSon")
        }
      }
      let s = "Adresse CAN : \(self.mNumeroCarteSon + 224)"
      self.mAdresseCANCarteSonTextField?.stringValue = s
      self.willChangeValue (forKey: "mCatalogueSonDuPIC")
      self.mCatalogueSonDuPIC.removeAll ()
      self.didChangeValue (forKey: "mCatalogueSonDuPIC")
    }
  }

  private var mConnection : NWConnection? = nil
  private var mReceivedData = [UInt8] ()
  private var mOpération : (any ProtocoleOpérationCarteSon)? = nil
  private var mTramesÀEnvoyer = [Trame] ()
  private var mFenêtreEnvoi = 0
  private var mTramesEnvoyées = 0
  private var mTramesReçues = 0
  private var mDateDébutOpération = Date ()
  private var mOpérationAchevée : Optional < (_ inOpération : any ProtocoleOpérationCarteSon) -> Void > = nil

  //································································································
  //  Catalogue des sons
  //································································································

  @objc var mCatalogueSonDuPIC = [EntréeCatalogueSonDuPic] ()
  private var mArrayControllerCatalogueSonDuPIC = NSArrayController ()
  @objc var mCatalogueSonDuDocument = [EntréeCatalogueSonDuDocument] ()
  private var mArrayControllerCatalogueSonDuDocument = NSArrayController ()
  @objc var mStatutFinDuCatalogueDesSonsDuDocument = ""

  //································································································

  deinit {
//    DispatchQueue.main.async {
//      self.stop ()
    self.mConnection?.cancel ()
    self.mConnection = nil
    self.mReceivedData.removeAll ()
    self.mTramesÀEnvoyer.removeAll ()
//    }
  }

  //································································································

  override var windowNibName : NSNib.Name? {
    return NSNib.Name ("DocumentCarteSon")
  }

  //································································································

  override func data (ofType typeName: String) throws -> Data {
    var array = [DescriptionEntréeCatalogueSonDuDocument] ()
    for entrée in self.mCatalogueSonDuDocument {
      array.append (entrée.descriptionSon)
    }
    let encoder = JSONEncoder ()
    encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
    let data = try encoder.encode (array)

//    var array = ["\(self.mNumeroCarteSon)"]
//    for entrée in self.mCatalogueSonDuDocument {
//      array.append (entrée.chaînePourEnregistrement ())
//    }
//    let s = array.joined (separator: "\n")
//    let data = s.data (using: .utf8)!
    return data
  }

  //································································································

  nonisolated override func read (from inData : Data, ofType typeName: String) throws {
//    try DispatchQueue.main.asyncAndWait {
//    let decoder = JSONDecoder ()
//    let array = try decoder.decode (DescriptionEntréeCatalogueSonDuDocument.self, from: inData)
//
//    }
    let s = String (data: inData, encoding: .utf8)!
    DispatchQueue.main.async {
      var array = s.components (separatedBy: "\n")
      self.undoManager?.disableUndoRegistration ()
        self.mNumeroCarteSon = Int (array [0])!
        array.removeFirst ()
        var catalogue = [EntréeCatalogueSonDuDocument] ()
        for entrée in array {
          catalogue.append (EntréeCatalogueSonDuDocument (chaîne: entrée))
        }
        self.initialiserCatalogueDocument (catalogue)
      self.undoManager?.enableUndoRegistration ()
    }
  }

  //································································································

  override func windowControllerDidLoadNib (_ inWindowController : NSWindowController) {
    self.mNuméroCarteSonPopUpButton?.bind (
      .selectedIndex,
      to: self, withKeyPath: #keyPath (mNumeroCarteSon),
      options: nil
    )
  //--- Pour déclencher le didSet de la propriété
    let n = self.mNumeroCarteSon
    self.mNumeroCarteSon = n
  //---
    self.mBoutonAnnuler?.target = self
    self.mBoutonAnnuler?.action = #selector (Self.annulerOperation (_:))
  //---
    self.mArrayControllerCatalogueSonDuPIC.bind (
      .contentArray,
      to: self,
      withKeyPath: "mCatalogueSonDuPIC",
      options: nil
    )
    self.mTableViewCatalogueDesSonsDuPIC?.tableColumn (withIdentifier: .init ("entree"))?.bind (
      .value,
      to: self.mArrayControllerCatalogueSonDuPIC,
      withKeyPath: "arrangedObjects.mChaine",
      options: nil
    )
    self.mBoutonTelechargerLeSon10Bits?.bind (
      .enabled,
      to: self.mArrayControllerCatalogueSonDuPIC,
      withKeyPath: "selection.mSonValide",
      options: nil
    )
    self.mBoutonTelechargerLeSon10Bits?.target = self
    self.mBoutonTelechargerLeSon10Bits?.action = #selector (Self.envoyerTéléchargementSon (_:))
    self.mCopierCataloguePICDansCatalogueDocument?.target = self
    self.mCopierCataloguePICDansCatalogueDocument?.action = #selector (Self.copierCataloguePICDansCatalogueDocument (_:))
  //---
    self.mArrayControllerCatalogueSonDuDocument.bind (
      .contentArray,
      to: self,
      withKeyPath: "mCatalogueSonDuDocument",
      options: nil
    )
    self.mTableViewCatalogueDesSonsDuDocument?.tableColumn (withIdentifier: .init ("entree"))?.bind (
      .value,
      to: self.mArrayControllerCatalogueSonDuDocument,
      withKeyPath: "arrangedObjects.mChaine",
      options: nil
    )
    self.willChangeValue (forKey: "mCatalogueSonDuDocument")
    self.didChangeValue (forKey: "mCatalogueSonDuDocument")
  //---
    self.mStatutFinDuCatalogueDesSonsDuDocumentTextField?.bind (
      .value,
      to: self,
      withKeyPath: "mStatutFinDuCatalogueDesSonsDuDocument",
      options: nil
    )
  //---
    super.windowControllerDidLoadNib (inWindowController)
  }

  //································································································

  @Sendable nonisolated private func stateDidChange (to inState : NWConnection.State) {
    DispatchQueue.main.async {
      switch inState {
      case .setup :
        self.mCommentaireProgression?.stringValue = "Configuration connexion en cours…"
      case .waiting (let error) :
        self.mCommentaireProgression?.stringValue = "Attente connexion \(error)…"
      case .preparing:
        self.mCommentaireProgression?.stringValue = "Préparation connexion…"
      case .ready:
        self.mCommentaireProgression?.stringValue = ""
        self.envoyerTrames ()
      case .failed (let error) :
        self.mCommentaireProgression?.stringValue = "Échec connexion, erreur \(error)"
        self.stop ()
      case .cancelled :
        self.stop ()
      @unknown default:
        ()
      }
    }
  }

  //································································································

  private func stop () {
    self.mConnection?.cancel ()
    self.mConnection = nil
    self.mReceivedData.removeAll ()
    self.mTramesÀEnvoyer.removeAll ()
  }

  //································································································

  private func startReceive () {
    self.mConnection?.receive (minimumIncompleteLength: 10, maximumLength: 1000) { inData, _, inIsDone, inError in
      DispatchQueue.main.async {
        if let data = inData, !data.isEmpty {
          // Swift.print ("did receive, data: \(data)")
          self.mReceivedData += data
          while self.mReceivedData.count >= 10 {
            let service = self.mReceivedData [0]
            let length = min (8, Int (self.mReceivedData [1]))
            var données = [UInt8] ()
            if length > 0 {
              for i in 0 ..< length {
                données.append (self.mReceivedData [i + 2])
              }
            }
            self.mReceivedData.removeFirst (10)
            let trameReçue = Trame (codeService: service, données: données)
            self.mOpération?.réception (trameReçue: trameReçue, tramesÀEnvoyer: &self.mTramesÀEnvoyer)
            self.mFenêtreEnvoi += 1
            self.mTramesReçues += 1
            self.envoyerTrames ()
            if let opération = self.mOpération {
              let (progression, total, terminé) = opération.progression ()
              if (total == progression) || (total == 0) || (progression == 0) {
                self.mIndicateurProgression?.isIndeterminate = true
              }else{
                self.mIndicateurProgression?.isIndeterminate = false
                self.mIndicateurProgression?.maxValue = Double (total)
                self.mIndicateurProgression?.doubleValue = Double (progression)
                let duréeÉcoulée = Date ().timeIntervalSince (self.mDateDébutOpération)
                let duréeRestante = duréeÉcoulée * Double (total - progression) / Double (progression)
                let perCent = (100.0 * Double (progression)) / Double (total)
                let s = "\(String (format: "%.1f", arguments: [perCent]))%, trames envoyées \(self.mTramesEnvoyées), reçues \(self.mTramesReçues), durée restante :\(duréeRestante.chaîneDuréeS)"
                self.mCommentaireProgression?.stringValue = s
              }
              if terminé {
                self.stop ()
                if let dialog = self.mPanelOperation, let parent = dialog.sheetParent {
                  parent.endSheet (dialog, returnCode: .stop)
                }
                self.mOpérationAchevée? (opération)
                self.mOpération = nil
                self.mOpérationAchevée = nil
                let duration = Date ().timeIntervalSince (self.mDateDébutOpération)
                Swift.print ("Terminé en\(duration.chaîneDuréeMS)")
              }
            }
          }
          if let _ = inError {
            // Swift.print ("did receive, error: \(error)")
            self.stop ()
            return
          }
          if inIsDone {
            // Swift.print ("did receive, EOF")
            self.stop ()
            return
          }
          self.startReceive ()
        }
      }
    }
  }

  //································································································

  private func envoyerTrames () {
    while self.mFenêtreEnvoi > 0, let trame = self.mTramesÀEnvoyer.first {
      self.mTramesÀEnvoyer.removeFirst ()
      self.mFenêtreEnvoi -= 1
      mTramesEnvoyées += 1
    //--- Envoyer la trame
      var data = Data ()
      data.append (trame.codeService)
      var n = min (8, trame.données.count)
      data.append (UInt8 (n))
      if n > 0 {
        for i in 0 ..< n {
          data.append (trame.données [i])
        }
      }
      while n < 8 {
        data.append (0)
        n += 1
      }
      self.mConnection?.send (content: data, isComplete: true, completion: .contentProcessed ({ inPossibleError in }))
    }
  }

  //································································································

  private func lancerOpération (opération inOperation : any ProtocoleOpérationCarteSon,
                                titre inTitre : String,
                                après inHandler : @escaping (any ProtocoleOpérationCarteSon) -> Void) {
    if let adresseIPcarteMezzanine = UserDefaults.standard.string (forKey: PREFS_ADRESSE_IP_CARTE_MEZZANINE),
       let panel = self.mPanelOperation {
      self.mOpérationAchevée = inHandler
      self.mReceivedData.removeAll ()
      self.mTramesÀEnvoyer.removeAll ()
    //--- Ouvrir la connexion
      let host = NWEndpoint.Host (adresseIPcarteMezzanine)
      let port = NWEndpoint.Port (8144)
      self.mConnection = NWConnection (host: host, port: port, using: .tcp)
      self.mConnection?.stateUpdateHandler = self.stateDidChange (to:)
      self.startReceive ()
      self.mConnection?.start (queue: .main)
    //--- Afficher le panel
      self.mTitreOperation?.stringValue = inTitre
      self.mIndicateurProgression?.minValue = 0.0
      self.mIndicateurProgression?.maxValue = 1.0
      self.mIndicateurProgression?.doubleValue = 0.0
      self.mIndicateurProgression?.isIndeterminate = true
      self.windowForSheet?.beginSheet (panel)
      self.mDateDébutOpération = Date ()
      self.mOpération = inOperation
      self.mFenêtreEnvoi = FENÊTRE_ENVOI
      self.mTramesEnvoyées = 0
      self.mTramesReçues = 0
      inOperation.démarrer (tramesÀEnvoyer: &self.mTramesÀEnvoyer)
    }
  }

  //································································································

  @objc func annulerOperation (_ inSender : Any?) {
    self.stop ()
    if let dialog = self.mPanelOperation, let parent = dialog.sheetParent {
      parent.endSheet (dialog, returnCode: .abort)
    }
    self.mOpération = nil
  }

  //································································································
  //  Télécharger le catalogue des sons du PIC
  //································································································

  @IBAction func envoyerRécupérationCatalogueEnEEPROM (_ inSender : Any?) {
    self.lancerOpération (
      opération: OpérationLectureCatalogue (numéroCarteSon: UInt8 (self.mNumeroCarteSon)),
      titre: "Lecture du catalogue des sons du PIC n°\(self.mNumeroCarteSon)",
      après: self.aprèsRécupérationCatalogueEnEEPROM
    )
  }

  //································································································

  fileprivate func aprèsRécupérationCatalogueEnEEPROM (_ inOpération : any ProtocoleOpérationCarteSon) {
    if let opération = inOpération as? OpérationLectureCatalogue {
      var catalogue = [EntréeCatalogueSonDuPic] ()
      var n = 0
      for numéroSon in 0 ..< 64 {
        let son = opération.entréeSon (pourIndice: numéroSon)
        switch son {
        case .son (let numéroSecteur, let longueur, let nom, let crc) :
          if numéroSecteur > n {
            let nombreInutilisés = numéroSecteur - n
            catalogue.append (EntréeCatalogueSonDuPic (espacement: nombreInutilisés))
          }else if numéroSecteur < n {
            let chevauchement = n - numéroSecteur
            catalogue.append (EntréeCatalogueSonDuPic (chevauchement: chevauchement))
          }
          catalogue.append (EntréeCatalogueSonDuPic (numéroSon: numéroSon, numéroSecteurDébut: numéroSecteur, longueurSon: longueur, nom: nom, crc: crc))
          let nombreSecteurs = 1 + (longueur - 1) / 4096
          n = numéroSecteur + nombreSecteurs
        default :
          ()
        }
      }
      if n < 4096 {
        let nombreInutilisés = 4096 - n
        catalogue.append (EntréeCatalogueSonDuPic (espacement: nombreInutilisés))
      }
      self.willChangeValue (forKey: "mCatalogueSonDuPIC")
      self.mCatalogueSonDuPIC = catalogue
      self.didChangeValue (forKey: "mCatalogueSonDuPIC")
    }
  }

  //································································································
  //  Télécharger un son à partir du PIC
  //································································································

  @IBAction func envoyerTéléchargementSon (_ inSender : Any?) {
    if let selectedIndex = self.mTableViewCatalogueDesSonsDuPIC?.selectedRow,
       selectedIndex >= 0,
       let (numéroSon, numéroSecteurDébut, longueurEnOctets) = self.mCatalogueSonDuPIC [selectedIndex].caractéristiqueSon () {
      self.lancerOpération (
        opération: OpérationTéléchargementSon (numéroCarteSon: UInt8 (self.mNumeroCarteSon), secteurDébut: numéroSecteurDébut, longueur: longueurEnOctets),
        titre: "Téléchargement du son n°\(numéroSon) du PIC n°\(self.mNumeroCarteSon) (\(longueurEnOctets) octets)",
        après: self.aprèsTéléchargementSon
      )
    }
  }

  //································································································

  fileprivate func aprèsTéléchargementSon (_ inOpération : any ProtocoleOpérationCarteSon) {
    if let opération = inOpération as? OpérationTéléchargementSon {
      let son10bits = opération.donnéesSon ()
      let dc = NSDocumentController.shared
      do{
        let possibleNewDocument : AnyObject = try dc.makeUntitledDocument (ofType: "name.pcmolinaro.pierre.Trans-Fer.sonDixBits")
        if let newDocument = possibleNewDocument as? DocumentJouerSon10bits {
          newDocument.définirSon (son10bits)
          dc.addDocument (newDocument)
          newDocument.makeWindowControllers ()
          newDocument.showWindows ()
        }
      }catch let inError {
        dc.presentError (inError)
      }
    }
  }

  //································································································

  fileprivate func initialiserCatalogueDocument (_ inCatalogue : [EntréeCatalogueSonDuDocument]) {
    var nouveauCatalogue = [EntréeCatalogueSonDuDocument] ()
    var numéroCourantSecteur = 0
    for entrée in inCatalogue {
      switch entrée.descriptionSon {
      case .espacement (_) :
        ()
      case .son (let numéro, let secteurDébut, let longueur, let nom, let crc) :
        let secteurDébutModifié : Int
        if secteurDébut < numéroCourantSecteur { // Chevauchement
          secteurDébutModifié = numéroCourantSecteur
        }else{
          if secteurDébut > numéroCourantSecteur { // Espacement
            let espacement = secteurDébut - numéroCourantSecteur
            nouveauCatalogue.append (EntréeCatalogueSonDuDocument (espacement: espacement))
          }
          secteurDébutModifié = secteurDébut
        }
        let entrée = EntréeCatalogueSonDuDocument (
          numéroSon: numéro,
          numéroSecteurDébut: secteurDébutModifié,
          longueurSon: longueur,
          nom: nom,
          crc: crc
        )
        nouveauCatalogue.append (entrée)
        numéroCourantSecteur = secteurDébutModifié + 1 + (longueur - 1) / 4096
      }
    }
    self.mTabViewCatalogue?.selectTabViewItem (at: 1)
    self.willChangeValue (forKey: "mCatalogueSonDuDocument")
      self.mCatalogueSonDuDocument = nouveauCatalogue
    self.didChangeValue (forKey: "mCatalogueSonDuDocument")
    self.willChangeValue (forKey: "mStatutFinDuCatalogueDesSonsDuDocument")
      if numéroCourantSecteur < 4096 {
        let secteursLibres = 4096 - numéroCourantSecteur
        self.mStatutFinDuCatalogueDesSonsDuDocument = "\(secteursLibres) secteurs libres à la fin de la Flash"
        // self.mStatutFinDuCatalogueDesSonsDuDocumentTextField?.textColor = .black
      }else if numéroCourantSecteur > 4096 {
        let secteursManquants = numéroCourantSecteur - 4096
        self.mStatutFinDuCatalogueDesSonsDuDocument = "Débordement de \(secteursManquants) secteurs"
        // self.mStatutFinDuCatalogueDesSonsDuDocumentTextField?.textColor = .red
      }
    self.didChangeValue (forKey: "mStatutFinDuCatalogueDesSonsDuDocument")
  }

  //································································································

  @objc func copierCataloguePICDansCatalogueDocument (_ inSender : Any?) {
    if self.fileURL == nil {
      let alert = NSAlert ()
      alert.messageText = "Pour réaliser cette opération, le document doit d'abord être enregistré"
      alert.beginSheetModal (for: self.windowForSheet!) { (response : NSApplication.ModalResponse) in }
    }else{
      var catalogue = [EntréeCatalogueSonDuDocument] ()
      for entrée in self.mCatalogueSonDuPIC {
        switch entrée.descriptionSon {
        case .chevauchement (_) :
          ()
        case .espacement (_) :
          ()
        case .son (let numéro, let secteurDébut, let longueur, let nom, let crc) :
          let entrée = EntréeCatalogueSonDuDocument (
            numéroSon: numéro,
            numéroSecteurDébut: secteurDébut,
            longueurSon: longueur,
            nom: nom,
            crc: crc
          )
          catalogue.append (entrée)
        }
      }
      self.initialiserCatalogueDocument (catalogue)
    }
  }

  //································································································

}

//——————————————————————————————————————————————————————————————————————————————————————————————————
