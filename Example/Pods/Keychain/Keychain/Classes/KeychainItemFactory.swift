//
//  KeychainItemFactory.swift
//  Pods
//
//  Created by Ardalan Samimi on 24/05/16.
//
//
import Foundation
/**
 *  This struct is a factory  that will generate instances of KeychainItem.
 */
public struct KeychainItemFactory {
  /**
   *  Load item's from the system keychain, returned as KeychainItem objects.
   *
   *  - Parameter query: A search query.
   *
   *  - Returns: An array of KeychainItem objects, created by the returned data from the keychain query.
   */
  public static func load(_ query: [String: AnyObject]) -> [KeychainItem] {
    let result = Keychain.load(query)
    var items: [KeychainItem] = []
    
    if result.success {
      if let array = result.data as? NSArray {
        for dict in array {
          if dict is [String : AnyObject] {
            let item = KeychainItem(attributeDictionary: dict as! [String : AnyObject])
            items.append(item)
          }
        }
      }
    }
    
    return items
  }
  
}
