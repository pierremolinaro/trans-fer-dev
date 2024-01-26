//
//  EntréeCatalogueSonDuDocument.swift
//  Trans-Fer
//
//  Created by Pierre Molinaro on 05/04/2022.
//
//——————————————————————————————————————————————————————————————————————————————————————————————————

import AppKit

//——————————————————————————————————————————————————————————————————————————————————————————————————

enum DescriptionEntréeCatalogueSonDuDocument {
  case espacement (Int)
  case son (Int, Int, Int, String, UInt32) // Numéro son, numéro secteur, longueur, nom, crc
}

//——————————————————————————————————————————————————————————————————————————————————————————————————

@MainActor class EntréeCatalogueSonDuDocument : NSObject {

  //------------------------------------------------------------------------------------------------

  private var mDescription : DescriptionEntréeCatalogueSonDuDocument
  @objc var mChaine : String
  @objc let mSonValide : Bool

  //------------------------------------------------------------------------------------------------

  init (espacement inNombreSecteurs : Int) {
    self.mDescription = .espacement (inNombreSecteurs)
    self.mChaine = (inNombreSecteurs > 1) ? "\(inNombreSecteurs) secteurs libres" : "\(inNombreSecteurs) secteur libre"
    self.mSonValide = false
  }

  //------------------------------------------------------------------------------------------------

  init (numéroSon inNuméroSon : Int,
        numéroSecteurDébut inNuméroSecteurDébut : Int,
        longueurSon inLongueur : Int,
        nom inNom : String,
        crc inCRC : UInt32) {
    self.mDescription = .son (inNuméroSon, inNuméroSecteurDébut, inLongueur, inNom, inCRC)
    let dernierSecteur = inNuméroSecteurDébut + (inLongueur - 1) / 4096
    self.mChaine = "n°\(inNuméroSon) : secteurs \(inNuméroSecteurDébut)...\(dernierSecteur), \(inLongueur) octets, nom '\(inNom)', CRC \(inCRC.hexString)"
    self.mSonValide = true
  }

  //------------------------------------------------------------------------------------------------

  convenience init (chaîne inChaîne : String) {
    let components = inChaîne.components (separatedBy: ":")
    if components [0] == "espacement" {
      self.init (espacement: Int (components [1])!)
    }else if components [0] == "son" {
      let numéroSon = Int (components [1])!
      let secteurDébut = Int (components [2])!
      let longueur = Int (components [3])!
      let nom = components [4]
      let crc = UInt32 (components [5])!
      self.init (numéroSon: numéroSon, numéroSecteurDébut: secteurDébut, longueurSon: longueur, nom: nom, crc: crc)
    }else{
      fatalError ()
    }
  }

  //------------------------------------------------------------------------------------------------

  func chaînePourEnregistrement () -> String {
    switch self.mDescription {
    case .son (let numéroSon, let secteurDébut, let longueur, let nom, let crc) :
      return "son:\(numéroSon):\(secteurDébut):\(longueur):\(nom):\(crc)"
    case .espacement (let nombreSecteurs) :
      return "espacement:\(nombreSecteurs)"
    }
  }

  //------------------------------------------------------------------------------------------------

  var descriptionSon : DescriptionEntréeCatalogueSonDuDocument {
    return self.mDescription
  }

  //------------------------------------------------------------------------------------------------

  var estEspacement : Bool {
    switch self.mDescription {
    case .son (_, _, _, _, _) :
      return false
    default :
      return true
    }
  }

  //------------------------------------------------------------------------------------------------

}

//——————————————————————————————————————————————————————————————————————————————————————————————————
