//
//  DocumentJouerSon10bits.swift
//  Trans-Fer
//
//  Created by Pierre Molinaro on 25/03/2022.
//
//——————————————————————————————————————————————————————————————————————————————————————————————————

import AppKit
import AudioToolbox

//——————————————————————————————————————————————————————————————————————————————————————————————————

extension UInt32 {

  //------------------------------------------------------------------------------------------------

  var hexString : String {
    var s = String (self, radix:16, uppercase: true)
    while s.count < 8 {
      s = "0" + s
    }
    return "0x" + s
  }

  //------------------------------------------------------------------------------------------------

}

//——————————————————————————————————————————————————————————————————————————————————————————————————

@objc(DocumentJouerSon10bits) class DocumentJouerSon10bits : NSDocument {

  //································································································

  @IBOutlet var mTailleFichierTextField : NSTextField? = nil
  @IBOutlet var mNombreÉchantillonsTextField : NSTextField? = nil
  @IBOutlet var mDuréeExécutionTextField : NSTextField? = nil
  @IBOutlet var mMinMaxMoyenneTextField : NSTextField? = nil
  @IBOutlet var mCRCTextField : NSTextField? = nil
  @IBOutlet var mBoutonJouer8bits  : NSButton? = nil
  @IBOutlet var mBoutonJouer10bits : NSButton? = nil

  //································································································

  private var mSon10bits = [UInt8] ()
//  private var mUserData : UserData? = nil
  private var mPossibleAudioQueue = AudioQueueRef (bitPattern: 0) ;

  //································································································

  deinit {
    if let audioQueue = self.mPossibleAudioQueue {
      AudioQueueDispose (audioQueue, true)
    }
  }

  //································································································

  func définirSon (_ inTableau : [UInt8]) {
    self.mSon10bits = inTableau
  }

  //································································································

  override var windowNibName : NSNib.Name? {
    return NSNib.Name ("DocumentJouerSon10bits")
  }

  //································································································

  override func data (ofType typeName: String) throws -> Data {
    return Data (self.mSon10bits)
  }

  //································································································

  override func read (from inData : Data, ofType typeName: String) throws {
    self.undoManager?.disableUndoRegistration ()
    self.mSon10bits = [UInt8] (inData)
    self.undoManager?.enableUndoRegistration ()
  }

  //································································································

  override func windowControllerDidLoadNib (_ windowController : NSWindowController) {
    self.mTailleFichierTextField?.stringValue = "Taille du fichier : \(self.mSon10bits.count) octets"
    self.mNombreÉchantillonsTextField?.stringValue = "Nombre d'échantillons : \(self.mSon10bits.count / 5)"
    let duréeExécutionMS = Int ((Double (self.mSon10bits.count) * 4.0 / 5.0) / 15.625)
    var s = ""
    if duréeExécutionMS >= 1_000 {
      s += " \(duréeExécutionMS / 1_000) s"
    }
    if (duréeExécutionMS % 1_000) != 0 {
      s += " \(duréeExécutionMS % 1_000) ms"
    }
    self.mDuréeExécutionTextField?.stringValue = "Durée :\(s)"
    self.mBoutonJouer8bits?.target = self
    self.mBoutonJouer8bits?.action = #selector (Self.jouerSon8bits (_:))
    self.mBoutonJouer10bits?.target = self
    self.mBoutonJouer10bits?.action = #selector (Self.jouerSon10bits (_:))
    var extensionByte : UInt8 = 0
    var cumul = 0
    var minimum = UInt16.max
    var maximum = UInt16.min
    for i in 0 ..< self.mSon10bits.count {
      if (i % 5) == 0 {
        extensionByte = self.mSon10bits [i]
      }else{
        var v = UInt16 (self.mSon10bits [i])
        v <<= 2
        v |= UInt16 (extensionByte) >> 6
        cumul += Int (v)
        minimum = min (minimum, v)
        maximum = max (maximum, v)
        extensionByte <<= 2
      }
    }
    self.mMinMaxMoyenneTextField?.stringValue = "Minimum : \(minimum), maximum : \(maximum), moyenne : \(cumul / self.mSon10bits.count)"
  //--- Calcul crc
    var crc : UInt32 = ~0
    for byte in self.mSon10bits {
      accumulateByteWithLookUpTable (byte: byte, crc: &crc)
    }
    self.mCRCTextField?.stringValue = "CRC : \(crc.hexString)"
  }

  //································································································

  @objc func jouerSon8bits (_ inSender : Any?) {
    var data8Bits = [UInt8] ()
    for i in 0 ..< self.mSon10bits.count {
      if (i % 5) != 0 {
        data8Bits.append (self.mSon10bits [i])
      }
    }
    var description = AudioStreamBasicDescription ()
    description.mSampleRate = 15_625.0
    description.mFormatID = kAudioFormatLinearPCM
    description.mFormatFlags = kLinearPCMFormatFlagIsBigEndian | kLinearPCMFormatFlagIsPacked
    description.mBytesPerPacket = 1
    description.mFramesPerPacket = 1
    description.mBytesPerFrame = 1
    description.mChannelsPerFrame = 1
    description.mBitsPerChannel = 8
    if let audioQueue = self.mPossibleAudioQueue {
      AudioQueueDispose (audioQueue, true)
    }
//    self.mUserData = UserData (self.mBoutonJouer8bits, self.mBoutonJouer10bits)
    var status = AudioQueueNewOutput (&description,
                                      audioCallBack,
                                      Unmanaged.passUnretained (self).toOpaque (), // User data, pass self as raw pointer
                                      nil, nil,
                                      0,
                                      &self.mPossibleAudioQueue)
    var informativeText = "AudioQueueNewOutput"
    if status == 0, let audioQueue = self.mPossibleAudioQueue {
      var buffer = UnsafeMutablePointer <AudioQueueBuffer> (bitPattern: 0)
      if status == 0 {
        status = AudioQueueAllocateBuffer (audioQueue, UInt32 (data8Bits.count), &buffer)
        informativeText = "AudioQueueAllocateBuffer"
      }
      if status == 0 {
        buffer!.pointee.mAudioData.copyMemory (from: data8Bits, byteCount: data8Bits.count)
        buffer!.pointee.mAudioDataByteSize = UInt32 (data8Bits.count)
        status = AudioQueueEnqueueBuffer (audioQueue, buffer!, 0, nil)
        informativeText = "AudioQueueEnqueueBuffer"
      }
      if status == 0 {
        status = AudioQueuePrime (audioQueue, 0, nil)
        informativeText = "AudioQueuePrime"
      }
      if status == 0 {
        status = AudioQueueStart (audioQueue, nil)
        informativeText = "AudioQueueStart"
      }
      if status == 0 {
        self.mBoutonJouer8bits?.isEnabled = false
        self.mBoutonJouer10bits?.isEnabled = false
      }
    }
    if status != 0 {
      let error = NSError (domain: NSOSStatusErrorDomain, code: Int (status), userInfo: nil)
      let alert = NSAlert (error: error)
      alert.informativeText = informativeText
      alert.beginSheetModal (for: self.windowForSheet!, completionHandler: nil)
    }
  }

  //································································································

  @objc func jouerSon10bits (_ inSender : Any?) {
    var data10Bits = [UInt16] ()
    var extensionByte : UInt8 = 0
    //var cumul = 0
    for i in 0 ..< self.mSon10bits.count {
      if (i % 5) == 0 {
        extensionByte = self.mSon10bits [i]
      }else{
        var v = Int16 (self.mSon10bits [i])
        let e = Int16 (extensionByte) >> 6
        v <<= 7
        v |= e << 5
        //cumul += Int (v)
        v -= 16_383
        data10Bits.append (UInt16 (bitPattern: v).byteSwapped)
        extensionByte <<= 2
      }
    }
    //Swift.print ("Moyenne \(cumul / self.mSon10bits.count)")
    var description = AudioStreamBasicDescription ()
    description.mSampleRate = 15_625.0
    description.mFormatID = kAudioFormatLinearPCM
    description.mFormatFlags = kAudioFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsBigEndian | kLinearPCMFormatFlagIsPacked
    description.mBitsPerChannel = 16
    description.mChannelsPerFrame = 1
    description.mBytesPerPacket = 2
    description.mBytesPerFrame = 2
    description.mFramesPerPacket = 1
    if let audioQueue = self.mPossibleAudioQueue {
      AudioQueueDispose (audioQueue, true)
    }
//    self.mUserData = UserData (self.mBoutonJouer8bits, self.mBoutonJouer10bits)
    var status = AudioQueueNewOutput (&description,
                                      audioCallBack,
                                      Unmanaged.passUnretained (self).toOpaque (), // User data, pass self as raw pointer
                                      nil, nil,
                                      0,
                                      &self.mPossibleAudioQueue)
    var informativeText = "AudioQueueNewOutput"
    if status == 0, let audioQueue = self.mPossibleAudioQueue {
      var buffer = UnsafeMutablePointer <AudioQueueBuffer> (bitPattern: 0)
      if status == 0 {
        status = AudioQueueAllocateBuffer (audioQueue, UInt32 (data10Bits.count * 2), &buffer)
        informativeText = "AudioQueueAllocateBuffer"
      }
      if status == 0 {
        buffer!.pointee.mAudioData.copyMemory (from: data10Bits, byteCount: data10Bits.count * 2)
        buffer!.pointee.mAudioDataByteSize = UInt32 (data10Bits.count * 2)
        status = AudioQueueEnqueueBuffer (audioQueue, buffer!, 0, nil)
        informativeText = "AudioQueueEnqueueBuffer"
      }
      if status == 0 {
        status = AudioQueuePrime (audioQueue, 0, nil)
        informativeText = "AudioQueuePrime"
      }
      if status == 0 {
        status = AudioQueueStart (audioQueue, nil)
        informativeText = "AudioQueueStart"
      }
      if status == 0 {
        self.mBoutonJouer8bits?.isEnabled = false
        self.mBoutonJouer10bits?.isEnabled = false
      }
    }
    if status != 0 {
      let error = NSError (domain: NSOSStatusErrorDomain, code: Int (status), userInfo: nil)
      let alert = NSAlert (error: error)
      alert.informativeText = informativeText
      alert.beginSheetModal (for: self.windowForSheet!, completionHandler: nil)
    }
  }

  //································································································

}


//——————————————————————————————————————————————————————————————————————————————————————————————————

//private struct UserData {
//  private(set) var mBoutonJouer8bits  : NSButton? = nil
//  private(set) var mBoutonJouer10bits : NSButton? = nil
//
//  init (_ inBoutonJouer8bits : NSButton?, _ inBoutonJouer10bits  : NSButton?) {
//    self.mBoutonJouer8bits  = inBoutonJouer8bits
//    self.mBoutonJouer10bits = inBoutonJouer10bits
//  }
//}

//——————————————————————————————————————————————————————————————————————————————————————————————————

private let audioCallBack : AudioQueueOutputCallback = { inUserData, inAQ, inBuffer in
  if let ptr = inUserData {
    let w = Unmanaged <DocumentJouerSon10bits>.fromOpaque (ptr).takeUnretainedValue ()
    DispatchQueue.main.async {
      w.mBoutonJouer8bits?.isEnabled = true
      w.mBoutonJouer10bits?.isEnabled = true
    }
  }
}

//——————————————————————————————————————————————————————————————————————————————————————————————————
