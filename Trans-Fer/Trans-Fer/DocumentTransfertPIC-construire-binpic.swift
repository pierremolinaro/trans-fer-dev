//
//  DocumentTransfertPIC-construire-binpic.swift
//  Trans-Fer
//
//  Created by Pierre Molinaro on 18/04/2022.
//
//——————————————————————————————————————————————————————————————————————————————————————————————————

import Foundation

//——————————————————————————————————————————————————————————————————————————————————————————————————

extension DocumentTransfertPIC {

  //------------------------------------------------------------------------------------------------
  //   construireFichierBinaireDistribution
  //------------------------------------------------------------------------------------------------

  func construireFichierBinaireDistribution (_ SOURCE_PICCOLO_UPDATER : String,
                                             _ PICS_CIBLE : [UInt8],
                                             _ NOM_PIC_FIRMWARE : String) -> Int {
    appendCommandString ("Construire le fichier binaire de la distribution\n")
    var s = "PICs cibles :"
    for v in PICS_CIBLE {
      s += " \(v)"
    }
    appendMessageString (s + "\n")
  //-------------------------------------------------------- Read HEX file
    let documentDir = self.fileURL?.deletingLastPathComponent ().path ?? "?"
    let hexString = try! String (contentsOf: URL (fileURLWithPath: documentDir + "/" + SOURCE_PICCOLO_UPDATER))
    let hexLines = hexString.components (separatedBy: "\n")
    var codeDictionary = [UInt16 : UInt8] ()
    var adresseBase : UInt32? = nil
    for line in hexLines {
      if line != "" {
        var data = line.data (using: .ascii)!
        let b = data.remove (at: 0)
        if b != ASCII.colon.rawValue {
          appendErrorString ("Erreur, une ligne ne commence pas par ':'\n")
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
          appendErrorString ("Erreur, le caractère n'est pas un chiffre hex.\n")
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
    appendMessageString ("Adresse de flashage : 0x" + String (adresseDébut, radix: 16, uppercase: true) + "\n")
    contents.append (UInt8 ((adresseDébut >> 14) & 0xFF))
    contents.append (UInt8 ((adresseDébut >>  6) & 0xFF))
  //--- Écrire la description des adresses des PICs destinataires
    var adressesOrdonnées = PICS_CIBLE.sorted ()
    appendMessageString ("Adresses des PICs destinataires : \(adressesOrdonnées)\n")
    var adresseCourante = adressesOrdonnées.remove (at: 0)
    var nombreAdressesConsécutives : UInt8 = 1
    for adressePIC in adressesOrdonnées {
      if adressePIC == (adresseCourante + nombreAdressesConsécutives - 1) {
        appendErrorString ("Erreur, doublon dans la liste PICS_CIBLE : \(adressePIC) apparaît plusieurs fois\n")
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
    try! contents.write (to: URL (fileURLWithPath: documentDir + "/" + NOM_PIC_FIRMWARE + ".binpic"))
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
