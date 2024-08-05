//
//  DocumentTransfertRP2040-construire-binpic.swift
//  Trans-Fer
//
//  Created by Pierre Molinaro on 18/04/2022.
//
//——————————————————————————————————————————————————————————————————————————————————————————————————

import Foundation

//——————————————————————————————————————————————————————————————————————————————————————————————————

extension DocumentTransfertRP2040 {

  //------------------------------------------------------------------------------------------------
  //   construireFichierBinaireDistribution
  //------------------------------------------------------------------------------------------------

  func construireFichierBinaireDistribution (_ inRP2040Array : [UInt8],
                                             _ inNomFirmware : String) -> Int {
    appendCommandString ("③ Construire le fichier binaire de la distribution\n")
    var s = "RP2040 cibles :"
    for v in inRP2040Array {
      s += " \(v)"
    }
    appendMessageString (s + "\n")
  //-------------------------------------------------------- Read BIN file
    let BUILD_PATH = (self.fileURL?.deletingLastPathComponent ().path ?? "?") + "/arduino-build/"
    let binData = try! Data (contentsOf: URL (fileURLWithPath: BUILD_PATH + self.nomDossierCroquis + ".bin"))
  //--- Préparer la génération du fichier
    var contents = Data ()
  //--- Écrire l'adresse de base (zéro pour un binaire RP2040)
    contents.append (0)
    contents.append (0)
  //--- Écrire la description des adresses des PICs destinataires
    var adressesOrdonnées = inRP2040Array.sorted ()
    appendMessageString ("Adresses des RP2040 destinataires : \(adressesOrdonnées)\n")
    var adresseCourante = adressesOrdonnées.remove (at: 0)
    var nombreAdressesConsécutives : UInt8 = 1
    for adressePIC in adressesOrdonnées {
      if adressePIC == (adresseCourante + nombreAdressesConsécutives - 1) {
        appendErrorString ("Erreur, doublon dans la liste des RP2040 : \(adressePIC) apparaît plusieurs fois\n")
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
  //--- Écrire le code des RP2040
    let binDataLength = UInt32 (binData.count)
    appendMessageString ("Longueur code RP2040 : \(binDataLength) octets.\n")
    contents.append (UInt8 ((binDataLength >>  0) & 0xFF))
    contents.append (UInt8 ((binDataLength >>  8) & 0xFF))
    contents.append (UInt8 ((binDataLength >> 16) & 0xFF))
    contents.append (UInt8 ((binDataLength >> 24) & 0xFF))
    contents += binData
    var crc = UInt32.max // Ajouter le CRC de binData
    for byte in binData {
      accumulateByteWithLookUpTable (byte: byte, crc: &crc)
    }
    contents.append (UInt8 ((crc >> 24) & 0xFF))
    contents.append (UInt8 ((crc >> 16) & 0xFF))
    contents.append (UInt8 ((crc >>  8) & 0xFF))
    contents.append (UInt8 ((crc >>  0) & 0xFF))
  //--- Calculer le CRC
    crc = UInt32.max
    for byte in contents {
      accumulateByteWithLookUpTable (byte: byte, crc: &crc)
    }
    appendMessageString ("CRC: 0x" + String (crc, radix: 16, uppercase: true) + "\n")
    contents.append (UInt8 ((crc >> 24) & 0xFF))
    contents.append (UInt8 ((crc >> 16) & 0xFF))
    contents.append (UInt8 ((crc >>  8) & 0xFF))
    contents.append (UInt8 ((crc >>  0) & 0xFF))
  //-------------------------------------------------------- Check CRC
    crc = UInt32.max
    for byte in contents {
      accumulateByteWithLookUpTable (byte: byte, crc: &crc)
    }
    appendMessageString ("Vérification CRC: \(String (crc, radix: 16, uppercase: true)) (\((crc == 0) ? "ok" : "erreur"))\n") // Doit être 0
    if crc != 0 {
      return 4
    }
  //--- Écrire le fichier
    try! contents.write (to: URL (fileURLWithPath: BUILD_PATH + inNomFirmware + ".binpic"))
  //---
    return 0 // Ok
  }

  //------------------------------------------------------------------------------------------------
  //   parsePicsCible
  //------------------------------------------------------------------------------------------------

  func parsePicsCible (_ inString : String) -> ([UInt8], Int) {
    var result = [UInt8] ()
    let components = inString.components (separatedBy: ",")
    for v in components {
      let components2 = v.components (separatedBy: ":")
      if components2.count == 1 {
        if let adresse = UInt8 (components2 [0]) {
          result.append (adresse)
        }else{
          appendErrorString ("Erreur, \(v) n'est pas un nombre entre 0 et 255\n")
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
          appendErrorString ("Erreur, \(v) n'est pas un intervalle valide\n")
          return ([], 7)
        }
      }else{
        appendErrorString ("Erreur, \(v) n'est pas invalide\n")
        return ([], 8)
      }
    }
    return (result, 0)
  }

  //------------------------------------------------------------------------------------------------

}

//——————————————————————————————————————————————————————————————————————————————————————————————————
