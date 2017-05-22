//
//  KeychainItemClass.swift
//  Pods
//
//  Created by Ardalan Samimi on 24/05/16.
//
//
import Foundation
/**
 *  An enum representing the system keychain item types.
 */
public enum KeychainItemClass {
  /**
   *  Generic password item.
   */
  case genericPassword
  /**
   *  Internet password item.
   */
  case internetPassword
  /**
   *  Certificate item.
   */
  case certificate
  /**
   *  Cryptographic key item.
   */
  case key
  /**
   *  Identity item.
   */
  case identity
  /**
   *  The class item type will be returned as a string.
   */
  public var rawValue: String {
    switch self {
    case .genericPassword:
      return kSecClassGenericPassword as String
    case .internetPassword:
      return kSecClassInternetPassword as String
    case .certificate:
      return kSecClassCertificate as String
    case .key:
      return kSecClassKey as String
    case .identity:
      return kSecClassIdentity as String
    }
  }
  
}
