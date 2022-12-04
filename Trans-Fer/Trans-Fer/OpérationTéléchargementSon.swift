//
//  OpérationTéléchargementSon.swift
//  Trans-Fer
//
//  Created by Pierre Molinaro on 05/04/2022.
//
//——————————————————————————————————————————————————————————————————————————————————————————————————

import Foundation

//——————————————————————————————————————————————————————————————————————————————————————————————————

final class OpérationTéléchargementSon : ProtocoleOpérationCarteSon {

  //································································································

  private let mNuméroCarteSon : UInt8
  private let mNuméroSecteurDébut : UInt32
  private let mLongueur : UInt32
  private var mDonnées = [UInt8] ()
  private var mAdresseDemande : UInt32 = 0
  private var mAdresseRéponse : UInt32 = 0
  private var mOk = true

  //································································································

  init (numéroCarteSon inNuméro : UInt8, secteurDébut inSecteurDébut : UInt32, longueur inLongueur : Int) {
    self.mNuméroCarteSon = inNuméro
    self.mNuméroSecteurDébut = inSecteurDébut
    self.mLongueur = UInt32 (inLongueur)
  }

  //································································································

  func donnéesSon () -> [UInt8] {
    return self.mDonnées
  }

  //································································································

  private func envoyerTrameDemande (tramesÀEnvoyer outTrames : inout [Trame]) {
    let nombreDemandé = min (4, self.mLongueur - self.mAdresseDemande)
    if nombreDemandé > 0 {
      let trame = Trame (
        numéroCarteSon: self.mNuméroCarteSon,
        adresseFlashExterne: self.mNuméroSecteurDébut * 4096 + self.mAdresseDemande,
        nombreÀLire: UInt8 (nombreDemandé)
      )
      outTrames.append (trame)
      self.mAdresseDemande += nombreDemandé
    }
  }

  //································································································

  func démarrer (tramesÀEnvoyer outTrames : inout [Trame]) {
    self.envoyerTrameDemande (tramesÀEnvoyer: &outTrames)
    self.envoyerTrameDemande (tramesÀEnvoyer: &outTrames)
    self.envoyerTrameDemande (tramesÀEnvoyer: &outTrames)
  }

  //································································································

  func réception (trameReçue inTrame : Trame, tramesÀEnvoyer outTrames : inout [Trame]) {
//    var s = "Réception service \(inTrame.codeService) :"
//    for byte in inTrame.données {
//      s += " \(String (byte, radix: 16, uppercase: true))"
//    }
//    Swift.print (s)
    if inTrame.codeService <= 15 {
      let adresseReçue = inTrame.be32 (atIndex: 0) & 0x00FF_FFFF
      let adresseAttendue = self.mNuméroSecteurDébut * 4096 + self.mAdresseRéponse
 //     Swift.print ("adresseReçue \(adresseReçue.hexString), adresseAttendue \(adresseAttendue.hexString)")
      self.mOk = adresseReçue == adresseAttendue
      let nombreOctetsReçus = inTrame.données.count - 4
      for i in 0 ..< nombreOctetsReçus {
        self.mDonnées.append (inTrame.données [4 + i])
      }
      self.mAdresseRéponse += UInt32 (nombreOctetsReçus)
      self.envoyerTrameDemande (tramesÀEnvoyer: &outTrames)
    }
  }


  //································································································

   func progression () -> (Int, Int, Bool) {
     return (Int (self.mAdresseRéponse), Int (self.mLongueur), (self.mAdresseRéponse == self.mLongueur) || !self.mOk)
   }

  //································································································

}

//——————————————————————————————————————————————————————————————————————————————————————————————————

private extension Trame {

  //································································································

  init (numéroCarteSon inNuméroCarteSon : UInt8,
        adresseFlashExterne inAddresseFlashExterne : UInt32,
        nombreÀLire inNombre : UInt8) { // 1 ... 4
    self.codeService = inNuméroCarteSon
    var d = [UInt8] ()
    let adresse = 0x1000_0000 | inAddresseFlashExterne ;
    d.append (UInt8 ( adresse >> 24)) // Adresse en big endian
    d.append (UInt8 ((adresse >> 16) & 0xFF))
    d.append (UInt8 ((adresse >>  8) & 0xFF))
    d.append (UInt8 ( adresse        & 0xFF))
    d.append (inNombre) ; // On demande la lecture de inNombre octets
    self.données = d
  }

  //································································································

}

//——————————————————————————————————————————————————————————————————————————————————————————————————
