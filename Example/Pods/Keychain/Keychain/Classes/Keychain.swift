//
//  Keychain.swift
//
//  Created by Ardalan Samimi on 24/05/16.
//
import Foundation
/**
 *  Keychain is an easy-to-use wrapper for using the system keychain and offers a simple interface to store user credentials – with more advance features available.
 *
 *  - Author: Ardalan Samimi
 *
 *  - Version: 0.3.0
 *
 *  - Requires: iOS 8.0
 *
 *  - SeeAlso: [Keychain Reference](http://cocoadocs.org/docsets/Keychain/0.3.0/index.html)
 */
public struct Keychain {
  
  static let service: String = Bundle.main.bundleIdentifier ?? ""
  
  // MARK: - Basic Keychain Methods
  /**
   *  Quick save an item to the keychain.
   *
   *  - Parameters:
   *    - value: The string value to save to the keychain.
   *    - forKey: The name of the entry.
   *
   *  - Returns: True if operation was successful.
   */
  public static func save(_ value: String, forKey key: String) -> Bool {
    let query: [String: AnyObject] = [
      kSecClass as String       : (kSecClassGenericPassword as NSString),
      kSecAttrAccount as String : key as AnyObject,
      kSecAttrService as String : self.service as AnyObject,
      kSecValueData as String   : value.data(using: String.Encoding.utf8, allowLossyConversion: false)! as AnyObject
    ]

    return self.secItemAdd(query) == noErr
  }
  /**
   *  Load an item from the keychain.
   *
   *  - Parameter key: Name of the saved password.
   *
   *  - Returns: A string value.
   */
  public static func load(_ key: String) -> String? {
    let query: [String: AnyObject] = [
      kSecClass as String       : kSecClassGenericPassword as NSString,
      kSecMatchLimit as String  : kSecMatchLimitOne,
      kSecReturnData as String  : kCFBooleanTrue,
      kSecAttrService as String : self.service as AnyObject,
      kSecAttrAccount as String : key as AnyObject
    ]
    
    if let value = self.secItemCopy(query).data as? Data {
      return String(data: value, encoding: String.Encoding.utf8)!
    }
    
    return nil
  }
  /**
   *  Deletes an item from the keychain.
   *
   *  - Parameter key: Name of the item.
   *
   *  - Returns: A boolean value.
   */
  public static func delete(_ key: String) -> Bool {
    let query: [String: AnyObject] = [
      kSecClass as String       : kSecClassGenericPassword as NSString,
      kSecAttrService as String : self.service as AnyObject,
      kSecAttrAccount as String : key as AnyObject
    ]
    
    return self.secItemDelete(query) == noErr
  }
  
  // MARK: - Advanced Keychain Methods
  /**
   *  Save an item to the keychain.
   *
   *  This method allows for more advanced usage and requires a valid attributes dictionary.
   *
   *  - Parameters:
   *    - attributes: A dictionary containing an item class key-value pair and optional attribute key-value pairs specifying the item's attribute values.
   *
   *  - SeeAlso: [Keychain Services Reference](xcdoc://?url=developer.apple.com/library/ios/documentation/Security/Reference/keychainservices/index.html#//apple_ref/doc/constant_group/Attribute_Item_Keys)
   *
   *  - Returns: A tuple with two members, reflecting the status of the operation.
   */
  public static func save(_ attributes: [String: AnyObject]) -> (success: Bool, statusCode: OSStatus) {
    let status = self.secItemAdd(attributes)
    
    return (success: (status == noErr), statusCode: status)
  }
  /**
   *  Load an item from the keychain.
   *
   *  This method allows for more advanced usage and requires a valid attributes dictionary.
   *
   *  - Parameters:
   *    - query: A dictionary containing an item class specification and optional attributes for controlling the search.
   *
   *  - SeeAlso: [Keychain Services Reference](xcdoc://?url=developer.apple.com/library/ios/documentation/Security/Reference/keychainservices/index.html#//apple_ref/doc/constant_group/Attribute_Item_Keys)
   *
   *  - Returns: A tuple with three members, reflecting the status of the operation and the data fetched, if any.
   */
  public static func load(_ query: [String: AnyObject]) -> (success: Bool, statusCode: OSStatus, data: AnyObject?) {
    let result = secItemCopy(query)
    
    return (success: (result.status == errSecSuccess), statusCode: result.status, data: result.data)
  }
  /**
   *  Update an item in the keychain.
   *
   *  This method allows for more advanced usage and requires a valid attributes dictionary.
   *
   *  - Parameters:
   *    - query: A dictionary containing an item class specification and optional attributes for controlling the search. Specify the items whose values you wish to change.
   *    - attributes: A dictionary containing the attributes whose values should be changed, along with the new values. Only real keychain attributes are permitted in this dictionary (no "meta" attributes are allowed.).
   *
   *  - SeeAlso: [Keychain Services Reference](xcdoc://?url=developer.apple.com/library/ios/documentation/Security/Reference/keychainservices/index.html#//apple_ref/doc/constant_group/Attribute_Item_Keys)
   *
   *  - Returns: A tuple with three members, reflecting the status of the operation and the data fetched, if any.
   */
  public static func update(_ query: [String: AnyObject], attributes: [String: AnyObject]) -> (success: Bool, statusCode: OSStatus) {
    let result = secItemUpdate(query, attributes: attributes)
    return (success: (result == noErr), statusCode: result)
  }
  /**
   *  Delete an item from the Keychain.
   *
   *  This method allows for more advanced usage and requires a valid attributes dictionary.
   *
   *  - Parameters:
   *    - query: A dictionary containing an item class specification and optional attributes for controlling the search.
   *
   *  - SeeAlso: [Keychain Services Reference](xcdoc://?url=developer.apple.com/library/ios/documentation/Security/Reference/keychainservices/index.html#//apple_ref/doc/constant_group/Attribute_Item_Keys)
   *
   *  - Returns: A tuple with two members, reflecting the status of the operation.
   */
  public static func delete(_ query: [String: AnyObject]) -> (success: Bool, statusCode: OSStatus) {
    let result = secItemDelete(query)
    return (success: (result == noErr), statusCode: result)
  }
  
}

private extension Keychain {
  
  static func secItemCopy(_ query: [String: AnyObject]) -> (status: OSStatus, data: AnyObject?) {
    var result: AnyObject?
    let status: OSStatus = withUnsafeMutablePointer(to: &result) {
      SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
    }
    
    return (status, result)
  }

  static func secItemAdd(_ attributes: [String: AnyObject]) -> OSStatus {
    _ = self.secItemDelete(attributes)
    return SecItemAdd(attributes as CFDictionary, nil)
  }
  
  static func secItemUpdate(_ query: [String: AnyObject], attributes: [String: AnyObject]) -> OSStatus {
    return SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
  }
  
  static func secItemDelete(_ query: [String: AnyObject]) -> OSStatus {
    return SecItemDelete(query as CFDictionary)
  }
  
}
