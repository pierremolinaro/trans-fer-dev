//
//  AppDelegate-nouveau-transfert-rp2040.swift
//  Trans-Fer
//
//  Created by Pierre Molinaro on 18/04/2022.
//
//——————————————————————————————————————————————————————————————————————————————————————————————————

import AppKit

//——————————————————————————————————————————————————————————————————————————————————————————————————

extension AppDelegate {

  //····················································································································
  //  NEW DOCUMENT
  //····················································································································

  @IBAction func nouveauDocumentTransfertRP2040 (_ inSender : Any?) {
    let dc = NSDocumentController.shared
    do{
      let possibleNewDocument : AnyObject = try dc.makeUntitledDocument (ofType: "name.pcmolinaro.pierre.Trans-Fer.TransfertRP2040")
      if let newDocument = possibleNewDocument as? NSDocument {
        dc.addDocument (newDocument)
        newDocument.makeWindowControllers ()
        newDocument.showWindows ()
      }
    }catch let inError {
      dc.presentError (inError)
    }
  }

  //································································································

}

//——————————————————————————————————————————————————————————————————————————————————————————————————
