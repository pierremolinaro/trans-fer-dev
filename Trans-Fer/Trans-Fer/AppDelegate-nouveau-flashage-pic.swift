//
//  AppDelegate-nouveau-flashage-pic.swift
//  Trans-Fer
//
//  Created by Pierre Molinaro on 26/03/2022.
//
//——————————————————————————————————————————————————————————————————————————————————————————————————

import Cocoa

//——————————————————————————————————————————————————————————————————————————————————————————————————

extension AppDelegate {

  //····················································································································
  //  NEW DOCUMENT
  //····················································································································

  @IBAction func nouveauDocumentFlashagePIC (_ inSender : Any?) {
    let dc = NSDocumentController.shared
    do{
      let possibleNewDocument : AnyObject = try dc.makeUntitledDocument (ofType: "name.pcmolinaro.pierre.Trans-Fer.flashagepic")
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
