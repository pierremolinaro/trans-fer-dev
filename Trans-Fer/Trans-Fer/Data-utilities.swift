//
//  Data-utilities.swift
//  Trans-Fer
//
//  Created by Pierre Molinaro on 18/04/2022.
//
//——————————————————————————————————————————————————————————————————————————————————————————————————

import Foundation

//——————————————————————————————————————————————————————————————————————————————————————————————————

func parseHexDigit (_ ioData : inout Data, _ ioResult : inout UInt8, _ ioOk : inout Bool) {
  ioResult <<= 4
  let b = ioData.remove (at: 0)
  if (b >= ASCII.zero.rawValue) && (b <= ASCII.nine.rawValue) {
    ioResult |= b - ASCII.zero.rawValue
  }else if (b >= ASCII.A.rawValue) && (b <= ASCII.Z.rawValue) {
    ioResult |= b - ASCII.A.rawValue + 10
  }else if (b >= ASCII.a.rawValue) && (b <= ASCII.z.rawValue) {
    ioResult |= b - ASCII.a.rawValue + 10
  }else{
    ioOk = false
  }
}

//——————————————————————————————————————————————————————————————————————————————————————————————————

func parseByte (_ ioData : inout Data, _ ioOk : inout Bool) -> UInt8 {
  var result : UInt8 = 0
  parseHexDigit (&ioData, &result, &ioOk)
  parseHexDigit (&ioData, &result, &ioOk)
  return result
}

//——————————————————————————————————————————————————————————————————————————————————————————————————

func parseUInt16 (_ ioData : inout Data, _ ioOk : inout Bool) -> UInt16 {
  var r1 : UInt8 = 0
  parseHexDigit (&ioData, &r1, &ioOk)
  parseHexDigit (&ioData, &r1, &ioOk)
  var r2 : UInt8 = 0
  parseHexDigit (&ioData, &r2, &ioOk)
  parseHexDigit (&ioData, &r2, &ioOk)
  return (UInt16 (r1) << 8) | UInt16 (r2)
}

//——————————————————————————————————————————————————————————————————————————————————————————————————
