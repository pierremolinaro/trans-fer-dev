//
//  DocumentTransfertPIC-transformer-en-piccolo-data.swift
//  Trans-Fer
//
//  Created by Pierre Molinaro on 18/04/2022.
//
//——————————————————————————————————————————————————————————————————————————————————————————————————

import Foundation

//——————————————————————————————————————————————————————————————————————————————————————————————————

fileprivate struct Bloc {
  let mAdresseDébut : UInt16 // Multiple de 64
  let mDonnées : [UInt16] // Contient toujours 32 éléments (soit 64 octets)

  var contientQueDesUns : Bool {
    for data in self.mDonnées {
      if data != 0xFFFF {
        return false
      }
    }
    return true
  }
}

//——————————————————————————————————————————————————————————————————————————————————————————————————

extension DocumentTransfertPIC {

  //------------------------------------------------------------------------------------------------

  func conversionEnPiccoloData (_ inFichierHex : String) -> Int {
    appendCommandString ("Transformer en Piccolo Data\n")
    let documentDir = self.fileURL?.deletingLastPathComponent ().path ?? "?"
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
          appendErrorString ("  Erreur, la ligne ne commence pas par \":\"\n")
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
          appendErrorString ("  Erreur de phase sur caractère\n")
          return 2
        }
      //--- Vérifier la somme de contrôle
        var somme : UInt8 = 0
        for v in éléments {
          somme &+= v
        }
        if somme != 0 {
          appendErrorString ("  Erreur de somme de contrôle (\(somme))\n")
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
        appendErrorString ("  Erreur, caractère inconnu\n")
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
    appendMessageString ("  \(listBlocs.count) blocs\n")
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

  //------------------------------------------------------------------------------------------------

}

//——————————————————————————————————————————————————————————————————————————————————————————————————
