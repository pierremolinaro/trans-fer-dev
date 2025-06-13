//
//  AppDelegate-nouveau-document-son.swift
//  Trans-Fer
//
//  Created by Pierre Molinaro on 26/03/2022.
//
//——————————————————————————————————————————————————————————————————————————————————————————————————

import AppKit
import AudioToolbox

//——————————————————————————————————————————————————————————————————————————————————————————————————

@MainActor extension AppDelegate {

  //································································································

  @IBAction func nouveauDocumentSon10bitsÀPartirFichierWAV (_ inSender : Any?) {
    let op = NSOpenPanel ()
    op.allowsMultipleSelection = false
    op.canChooseDirectories = false
    op.canChooseFiles = true
    op.allowedFileTypes = ["wav"]
    op.begin { (inReturnCode : NSApplication.ModalResponse) in
      if inReturnCode == .OK {
        DispatchQueue.main.async {
          let url = op.urls [0]
          self.nouveauDocumentSon10bits (àPartirFichierWAVà15625Hz: url)
        }
      }
    }
  }

  //································································································

  func nouveauDocumentSon10bits (àPartirFichierWAVà15625Hz inURL : URL) {
    // print ("Fichier : \(inURL.lastPathComponent)")
    var optionalFileID = AudioFileID (bitPattern: 0)

    var status = AudioFileOpenURL (inURL as CFURL, .readPermission, 0, &optionalFileID)
    var informativeText = "AudioFileOpenURL"

    if status == 0, let fileID = optionalFileID {
      var description = AudioStreamBasicDescription ()
      if status == 0 {
        var p : UInt32 = UInt32 (MemoryLayout <AudioStreamBasicDescription>.stride)
        status = AudioFileGetProperty (fileID, kAudioFilePropertyDataFormat, &p, &description)
        informativeText = "AudioFileGetProperty"
      }
      var nombreOctets : UInt64 = 0
      if status == 0 {
        var p : UInt32 = 8
        status = AudioFileGetProperty (fileID, kAudioFilePropertyAudioDataByteCount, &p, &nombreOctets)
        informativeText = "AudioFileGetProperty"
      }
      var données = [UInt8] (repeating: 0, count: Int (nombreOctets))
      if status == 0 {
        var p = UInt32 (nombreOctets)
        status = AudioFileReadBytes (fileID, false, 0, &p, &données)
        informativeText = "AudioFileReadBytes"
      }
      AudioFileClose (fileID)
      if status != 0 {
        let error = NSError (domain: NSOSStatusErrorDomain, code: Int (status), userInfo: nil)
        let alert = NSAlert (error: error)
        alert.informativeText = informativeText
        _ = alert.runModal ()
      }
      var fréquenceÉchantillonageOk = true
      if status == 0, description.mSampleRate != 15_625.0 {
        fréquenceÉchantillonageOk = false
        let alert = NSAlert ()
        alert.messageText = "Le fichier WAV n'est pas échantillonné à 15 625 Hz."
        alert.informativeText = "La fréquence d'échantillonnage est \(description.mSampleRate) Hz."
        _ = alert.runModal ()
//        print ("  mSampleRate : \(description.mSampleRate)")
//        print ("  mFormatID : \(description.mFormatID)")
//        print ("  mFormatFlags : \(description.mFormatFlags)")
//        print ("  mBytesPerPacket : \(description.mBytesPerPacket)")
//        print ("  mFramesPerPacket : \(description.mFramesPerPacket)")
//        print ("  mBytesPerFrame : \(description.mBytesPerFrame)")
//        print ("  mChannelsPerFrame : \(description.mChannelsPerFrame)")
//        print ("  mBitsPerChannel : \(description.mBitsPerChannel)")
      }
    //--- Examiner les données brutes
      if status == 0, fréquenceÉchantillonageOk {
        let octetsParÉchantillon = Int (description.mBitsPerChannel) / 8 ;
        let nombreÉchantillons = Int (nombreOctets) / Int (description.mChannelsPerFrame) / octetsParÉchantillon ;
        var tableauDesÉchantillons = [Int64] ()
//        print ("  Octets par échantillon : \(octetsParÉchantillon)")
//        print ("  Nombre d'échantillons  : \(nombreÉchantillons)")
        var valeurMin : Int64 = Int64.max
        var valeurMax : Int64 = Int64.min
        var cumul : Int64 = 0
        let maxAmplitude = Int64 (1) << description.mBitsPerChannel
        for indiceÉchantillon in 0 ..< nombreÉchantillons {
          var échantillon : Int64 = 0
          for i in 0 ..< octetsParÉchantillon {
            échantillon *= 256 ;
            échantillon += Int64 (données [indiceÉchantillon * octetsParÉchantillon * Int (description.mChannelsPerFrame) + octetsParÉchantillon - i - 1])
          }
          if (octetsParÉchantillon > 1) && (échantillon >= (maxAmplitude / 2)) {
            échantillon -= maxAmplitude
          }
          tableauDesÉchantillons.append (échantillon)
          if (valeurMin > échantillon) {
            valeurMin = échantillon
          }
          if (valeurMax < échantillon) {
            valeurMax = échantillon
          }
          cumul += échantillon
        }
        // print ("  Données brutes --> Min : \(valeurMin), max : \(valeurMax), moyenne : \(cumul / Int64 (nombreOctets))")
      //--- Parcourir le tableau de façon à étaler les sons entre 0 et 1023
        var newMin : Int64 = 1024
        var newMax : Int64 = 0
        var newCumul : Int64 = 0
        let valeurSeuil : Int64 = 0
        for i in 0 ..< nombreÉchantillons {
          let v = valeurSeuil + ((valeurMax - tableauDesÉchantillons [i]) * (1023 - valeurSeuil)) / (valeurMax - valeurMin)
          tableauDesÉchantillons [i] = v
          newCumul += v
          if newMax < v {
            newMax = v
          }
          if newMin > v {
            newMin = v
          }
        }
        // print ("  Correction d'amplitude --> Min : \(newMin), max : \(newMax), moyenne : \(newCumul / Int64 (nombreÉchantillons))")
      //--- Construire un tableau binaire
        var son10bits = [UInt8] ()
        for i in 0 ..< tableauDesÉchantillons.count / 4 {
          let echantillon0 = tableauDesÉchantillons [4 * i + 0]
          let echantillon1 = tableauDesÉchantillons [4 * i + 1]
          let echantillon2 = tableauDesÉchantillons [4 * i + 2]
          let echantillon3 = tableauDesÉchantillons [4 * i + 3]
        // Calculer l'octet d'extension
          var octetExtension = UInt8 (echantillon0 & 3)
          octetExtension <<= 2
          octetExtension |= UInt8 (echantillon1 & 3)
          octetExtension <<= 2
          octetExtension |= UInt8 (echantillon2 & 3)
          octetExtension <<= 2
          octetExtension |= UInt8 (echantillon3 & 3)
        // Écrire les échantillons
          son10bits.append (octetExtension)
          son10bits.append (UInt8 (echantillon0 >> 2))
          son10bits.append (UInt8 (echantillon1 >> 2))
          son10bits.append (UInt8 (echantillon2 >> 2))
          son10bits.append (UInt8 (echantillon3 >> 2))
        }
        //--- Créer le nouveau document
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
  }

  //································································································

}

//——————————————————————————————————————————————————————————————————————————————————————————————————
