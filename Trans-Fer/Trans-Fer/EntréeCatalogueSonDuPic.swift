//
//  EntréeCatalogueSonDuPic.swift
//  Trans-Fer
//
//  Created by Pierre Molinaro on 05/04/2022.
//
//——————————————————————————————————————————————————————————————————————————————————————————————————

import AppKit

//——————————————————————————————————————————————————————————————————————————————————————————————————

enum DescriptionEntréeCatalogueSonDuPic {
  case chevauchement (Int)
  case espacement (Int)
  case son (Int, Int, Int, String, UInt32) // Numéro son, numéro secteur, longueur, nom, crc
}

//——————————————————————————————————————————————————————————————————————————————————————————————————

class EntréeCatalogueSonDuPic : NSObject {

  //------------------------------------------------------------------------------------------------

  private var mDescription : DescriptionEntréeCatalogueSonDuPic
  @objc var mChaine : String
  @objc let mSonValide : Bool

  //------------------------------------------------------------------------------------------------

  init (espacement inNombreSecteurs : Int) {
    self.mDescription = .espacement (inNombreSecteurs)
    self.mChaine = (inNombreSecteurs > 1) ? "\(inNombreSecteurs) secteurs libres" : "\(inNombreSecteurs) secteur libre"
    self.mSonValide = false
  }

  //------------------------------------------------------------------------------------------------

  init (chevauchement inNombreSecteurs : Int) {
    self.mDescription = .chevauchement (inNombreSecteurs)
    self.mChaine = "Chevauchement sur \(inNombreSecteurs) secteur\((inNombreSecteurs > 1) ? "s" : "")"
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

  func caractéristiqueSon () -> (Int, UInt32, Int)? { // Numéro son, Numéro secteur début, longueur
    switch self.mDescription {
    case .son (let numéroSon, let secteurDébut, let longueur, _, _) :
      return (numéroSon, UInt32 (secteurDébut), longueur)
    default :
      return nil
    }
  }

  //------------------------------------------------------------------------------------------------

  var descriptionSon : DescriptionEntréeCatalogueSonDuPic {
    return self.mDescription
  }
  
  //------------------------------------------------------------------------------------------------

}

//——————————————————————————————————————————————————————————————————————————————————————————————————
