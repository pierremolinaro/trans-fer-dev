//
//  DocumentCarteSon-operation-lecture-catalogue.swift
//  Trans-Fer
//
//  Created by Pierre Molinaro on 27/03/2022.
//
//——————————————————————————————————————————————————————————————————————————————————————————————————

import AppKit

//——————————————————————————————————————————————————————————————————————————————————————————————————

enum EntréeCatalogueSon {
  case inconnue
  case inutilisée
  case longueurPartielle (UInt16, UInt32) // Numéro secteur, longueur partielle (2 octets)
  case nomPartiel (UInt16, UInt32, Data) // Numéro secteur, longueur, nom partiel
  case attenteCRC (UInt16, UInt32, String) // Numéro secteur, longueur, nom
  case son (Int, Int, String, UInt32) // Numéro secteur, longueur, nom, crc

  var terminé : Bool {
    switch self {
    case .inconnue : return false
    case .longueurPartielle : return false
    case .nomPartiel : return false
    case .attenteCRC : return false
    case .inutilisée : return true
    case .son : return true
    }
  }
}

//——————————————————————————————————————————————————————————————————————————————————————————————————

final class OpérationLectureCatalogue : ProtocoleOpérationCarteSon {

  //································································································

  let mNuméroCarteSon : UInt8
  var mCatalogueSons = [EntréeCatalogueSon] (repeating: .inconnue, count: 64)
  
  //································································································

  init (numéroCarteSon inNuméro : UInt8) {
    self.mNuméroCarteSon = inNuméro
  }


  //································································································

  func entréeSon (pourIndice inIndex : Int) -> EntréeCatalogueSon {
    return mCatalogueSons [inIndex]
  }

  //································································································

  func démarrer (tramesÀEnvoyer outTrames : inout [Trame]) {
  //--- Envoyer les trames pour lire le début de chaque entrée
    for numéroSon : UInt32 in 0 ..< 64 {
      let trame = Trame (numéroCarteSon: self.mNuméroCarteSon, numéroSon: numéroSon, offsetCatalogue: 0)
      outTrames.append (trame)
    }
  }

  //································································································

  func réception (trameReçue inTrame : Trame, tramesÀEnvoyer outTrames : inout [Trame]) {
//    var s = "Réception service \(inTrame.codeService) :"
//    for byte in inTrame.données {
//      s += " \(String (byte, radix: 16, uppercase: true))"
//    }
//    Swift.print (s)
    if inTrame.codeService <= 15 {
      self.service_0_à_15 (trame: inTrame, tramesÀEnvoyer : &outTrames)
    }else if (inTrame.codeService <= 31) && (inTrame.données.count == 5) {
      self.service_16_à_31 (trame: inTrame, tramesÀEnvoyer : &outTrames)
    }
  }

  //································································································

  func service_0_à_15 (trame inTrame : Trame, tramesÀEnvoyer outTrames : inout [Trame]) {
    let adresse = inTrame.be32 (atIndex: 0)
    let numéroSon = Int (adresse >> 4) - 0x1000
    let offsetCatalogue = Int (adresse & 15)
    if (numéroSon >= 0) && (numéroSon < 64) {
      switch (self.mCatalogueSons [numéroSon]) {
      case .inconnue :
        if offsetCatalogue == 0 {
          let numéroSecteur = inTrame.be16 (atIndex: 4)
          if numéroSecteur == 0xFFFF {
            self.mCatalogueSons [numéroSon] = .inutilisée
            // Swift.print ("n°\(numéroSon) : inutilisé")
          }else{
            let longueurPartielle = UInt32 (inTrame.be16 (atIndex: 6))
            self.mCatalogueSons [numéroSon] = .longueurPartielle (numéroSecteur, longueurPartielle)
            let trame = Trame (numéroCarteSon: self.mNuméroCarteSon, numéroSon: UInt32 (numéroSon), offsetCatalogue: 4)
            outTrames.append (trame)
          }
        }
      case .inutilisée :
        ()
      case .longueurPartielle (let numéroSecteur, let longueurPartielle) :
        if offsetCatalogue == 4 {
          var longueur = longueurPartielle << 8
          longueur |= UInt32 (inTrame.données [4])
          var idx = 5
          var partiel = true
          var nomPartiel = Data ()
          while partiel && (idx < 8) {
            partiel = inTrame.données [idx] != 0xFF
            if partiel {
              nomPartiel.append (inTrame.données [idx])
              idx += 1
            }
          }
          if !partiel {
            if nomPartiel.isEmpty {
              self.mCatalogueSons [numéroSon] = .attenteCRC (numéroSecteur, longueur, "")
              let trame = Trame (numéroCarteSon: self.mNuméroCarteSon, numéroSonPourCalculCRC: UInt8 (numéroSon))
              outTrames.append (trame)
//              Swift.print ("n°\(numéroSon), secteur \(numéroSecteur), longueur \(longueur), nom ''")
            }else{
              let s = String (data: nomPartiel, encoding: .utf8)!
              self.mCatalogueSons [numéroSon] = .attenteCRC (numéroSecteur, longueur, s)
              let trame = Trame (numéroCarteSon: self.mNuméroCarteSon, numéroSonPourCalculCRC: UInt8 (numéroSon))
              outTrames.append (trame)
            }
          }else{
            self.mCatalogueSons [numéroSon] = .nomPartiel (numéroSecteur, longueur, nomPartiel)
            let trame = Trame (numéroCarteSon: self.mNuméroCarteSon, numéroSon: UInt32 (numéroSon), offsetCatalogue: 8)
            outTrames.append (trame)
          }
        }
      case .nomPartiel (let numéroSecteur, let longueur, var nomPartiel) :
        // Swift.print ("offsetCatalogue \(offsetCatalogue), nomPartiel.count \(nomPartiel.count)")
        if offsetCatalogue == (nomPartiel.count + 5) {
          var idx = 4
          var partiel = true
          while partiel && (idx < 8) {
            partiel = inTrame.données [idx] != 0xFF
            if partiel {
              nomPartiel.append (inTrame.données [idx])
              idx += 1
            }
          }
          if !partiel || (offsetCatalogue == 12) {
            let s = String (data: nomPartiel, encoding: .utf8)!
            self.mCatalogueSons [numéroSon] = .attenteCRC (numéroSecteur, longueur, s)
            let trame = Trame (numéroCarteSon: self.mNuméroCarteSon, numéroSonPourCalculCRC: UInt8 (numéroSon))
            outTrames.append (trame)
//            Swift.print ("n°\(numéroSon), secteur \(numéroSecteur), longueur \(longueur), nom '\(s)'")
          }else{
            self.mCatalogueSons [numéroSon] = .nomPartiel (numéroSecteur, longueur, nomPartiel)
            let trame = Trame (numéroCarteSon: self.mNuméroCarteSon, numéroSon: UInt32 (numéroSon), offsetCatalogue: UInt32 (offsetCatalogue) + 4)
            outTrames.append (trame)
          }
        }
      default :
        ()
      }
    }
  }

  //································································································

  func service_16_à_31 (trame inTrame : Trame, tramesÀEnvoyer outTrames : inout [Trame]) {
    let numéroSon = Int (inTrame.données [4])
    if numéroSon < 64 {
      switch (self.mCatalogueSons [numéroSon]) {
      case .attenteCRC (let numéroSecteur, let longueur, let nom) :
        let crc = inTrame.be32 (atIndex: 0)
        self.mCatalogueSons [numéroSon] = .son (Int (numéroSecteur), Int (longueur), nom, crc)
        // Swift.print ("n°\(numéroSon), secteur \(numéroSecteur), longueur \(longueur), nom '\(nom)', CRC \(crc.hexString)")
      default :
        ()
      }
    }
  }

  //································································································

   func progression () -> (Int, Int,Bool) {
     var compteurTerminés = 0
     var totalTerminés = 0
     var terminé = true
     for entrée in self.mCatalogueSons {
       switch entrée {
       case .inconnue :
         terminé = false
       case .inutilisée :
         ()
       case .longueurPartielle :
         terminé = false
       case .nomPartiel (_, let longueur, _) :
         totalTerminés += Int (longueur)
         terminé = false
       case .attenteCRC (_, let longueur, _) :
         totalTerminés += Int (longueur)
         terminé = false
       case .son (_, let longueur, _, _) :
         compteurTerminés += Int (longueur)
         totalTerminés += Int (longueur)
       }
     }
     return (compteurTerminés, totalTerminés, terminé)
   }

  //································································································

}

//——————————————————————————————————————————————————————————————————————————————————————————————————

private extension Trame {

  //································································································

  init (numéroCarteSon inNuméroCarteSon : UInt8, numéroSon inNuméroSon : UInt32, offsetCatalogue inOffset : UInt32) {
    self.codeService = inNuméroCarteSon
    var d = [UInt8] ()
    let adresseSonEnEEPROM = 0x1_0000 | (inNuméroSon << 4) | inOffset ;
    d.append (UInt8 (adresseSonEnEEPROM >> 24)) // Adresse en big endian
    d.append (UInt8 ((adresseSonEnEEPROM >> 16) & 0xFF))
    d.append (UInt8 ((adresseSonEnEEPROM >>  8) & 0xFF))
    d.append (UInt8 ( adresseSonEnEEPROM        & 0xFF))
    d.append (4) ; // On demande la lecture de 4 octets
    self.données = d
  }

  //································································································

  init (numéroCarteSon inNuméroCarteSon : UInt8, numéroSonPourCalculCRC inNuméroSon : UInt8) {
    self.codeService = 48
    self.données = [inNuméroCarteSon, inNuméroSon]
  }

  //································································································

}

//——————————————————————————————————————————————————————————————————————————————————————————————————
