//
//  AppDelegate-conversion-son.swift
//  Trans-Fer
//
//  Created by Pierre Molinaro on 26/03/2022.
//
//——————————————————————————————————————————————————————————————————————————————————————————————————
// https://stackoverflow.com/questions/60711929/change-sample-rate-with-audioconverter
//——————————————————————————————————————————————————————————————————————————————————————————————————

import AppKit
import AudioToolbox
import AVFoundation

//——————————————————————————————————————————————————————————————————————————————————————————————————

extension AppDelegate {

  //································································································

  @IBAction func nouveauDocumentSon10bitsÀPartirFichierSon (_ inSender : Any?) {
    let op = NSOpenPanel ()
    op.allowsMultipleSelection = false
    op.canChooseDirectories = false
    op.canChooseFiles = true
    op.allowedFileTypes = ["wav", "mp3"]
    op.begin { (inReturnCode : NSApplication.ModalResponse) in
      if inReturnCode == .OK {
        let url = op.urls [0]
        DispatchQueue.main.async { self.nouveauDocumentSon10bits (àPartirFichierSon: url) }
      }
    }
  }

  //································································································

  private func nouveauDocumentSon10bits (àPartirFichierSon inSourceURL : URL) {
    let outputSampleRate = 15_625.0
    let sourceFile : AVAudioFile
    let format : AVAudioFormat

    do{
      sourceFile = try AVAudioFile (forReading: inSourceURL)
      format = sourceFile.processingFormat
    }catch{
      fatalError ("Unable to load the source audio file: \(error.localizedDescription).")
    }

    let sourceSettings = sourceFile.fileFormat.settings
    var outputSettings = sourceSettings
    outputSettings [AVSampleRateKey] = outputSampleRate
    outputSettings [AVFormatIDKey] = kAudioFormatLinearPCM

    let engine = AVAudioEngine ()
    let player = AVAudioPlayerNode ()

    engine.attach (player)

    // Connect the nodes.
    engine.connect (player, to: engine.mainMixerNode, format: format)

    // Schedule the source file.
    player.scheduleFile (sourceFile, at: nil)

    do {
        // The maximum number of frames the engine renders in any single render call.
        let maxFrames: AVAudioFrameCount = 4096
        let outputAudioFormat = AVAudioFormat (standardFormatWithSampleRate: outputSampleRate, channels: sourceFile.fileFormat.channelCount)!
        try engine.enableManualRenderingMode (.offline, format: outputAudioFormat, maximumFrameCount: maxFrames)
    } catch {
        fatalError("Enabling manual rendering mode failed: \(error).")
    }

    do {
      try engine.start ()
      player.play ()
    } catch {
        fatalError("Unable to start audio engine: \(error).")
    }

    let buffer = AVAudioPCMBuffer (pcmFormat: engine.manualRenderingFormat, frameCapacity: engine.manualRenderingMaximumFrameCount)!

    let outputURL = URL (fileURLWithPath: NSTemporaryDirectory () + "\(Date ()).wav")
    // Swift.print ("outputURL \(outputURL)")
    var outputFile: AVAudioFile?
    do {
      outputFile = try AVAudioFile (forWriting: outputURL, settings: outputSettings)
    }catch{
      fatalError("Unable to open output audio file: \(error).")
    }

    let outputLengthD = Double (sourceFile.length) * outputSampleRate / sourceFile.fileFormat.sampleRate
    let outputLength = Int64 (ceil (outputLengthD)) // no sample left behind

    while engine.manualRenderingSampleTime < outputLength {

        do {
            let frameCount = outputLength - engine.manualRenderingSampleTime
            let framesToRender = min(AVAudioFrameCount(frameCount), buffer.frameCapacity)

            let status = try engine.renderOffline (framesToRender, to: buffer)

            switch status {

            case .success:
                // The data rendered successfully. Write it to the output file.
                try outputFile?.write (from: buffer)

            case .insufficientDataFromInputNode:
                // Applicable only when using the input node as one of the sources.
                break

            case .cannotDoInCurrentContext:
                // The engine couldn't render in the current render call.
                // Retry in the next iteration.
                break

            case .error:
                // An error occurred while rendering the audio.
                fatalError("The manual rendering failed.")
            @unknown default:
                fatalError("Unknown default.")

            }
        } catch {
            fatalError("The manual rendering failed: \(error).")
        }
    }

    // Stop the player node and engine.
    player.stop()
    engine.stop()

    outputFile = nil // AVAudioFile won't close until it goes out of scope, so we set output file back to nil here  }
    self.nouveauDocumentSon10bits (àPartirFichierWAVà15625Hz: outputURL)
  }

  //································································································

}

//——————————————————————————————————————————————————————————————————————————————————————————————————

