//
//  AppDelegate-nouveau-flashage-pic.swift
//  Trans-Fer
//
//  Created by Pierre Molinaro on 26/03/2022.
//
//——————————————————————————————————————————————————————————————————————————————————————————————————

import AppKit

//——————————————————————————————————————————————————————————————————————————————————————————————————

extension AppDelegate {

  //····················································································································
  //  NEW DOCUMENT
  //····················································································································

  @IBAction func nouveauDocumentTransfertPIC (_ inSender : Any?) {
    let dc = NSDocumentController.shared
    do{
      let possibleNewDocument : AnyObject = try dc.makeUntitledDocument (ofType: "name.pcmolinaro.pierre.Trans-Fer.TransfertPIC")
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
