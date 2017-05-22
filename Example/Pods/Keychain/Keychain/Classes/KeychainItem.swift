//
//  KeychainItem.swift
//  Pods
//
//  Created by Ardalan Samimi on 24/05/16.
//
//
import Foundation
/**
 *  Create, save and load items from the system keychain.
 */
open class KeychainItem {
  
  // MARK: - Public Properties
  
  /**
   *  The value to save.
   */
  open var value: String? {
    get {
      if let data = self.attributes[kSecValueData as String] as? Data {
        return String(data: data, encoding: String.Encoding.utf8)
      }
      
      return nil
    }
    set {
      if let value = newValue {
        self.attributes[kSecValueData as String] = value.data(using: String.Encoding.utf8, allowLossyConversion: false)! as AnyObject?
      } else {
        self.attributes.removeValue(forKey: kSecValueData as String)
      }
    }
  }
  /**
   *  Access group key.
   *
   *  Indicates which access group an item is in. Access groups can be used to share keychain items among two or more applications.
   */
  open var accessGroup: String? {
    get {
      return self.attributes[kSecAttrAccessGroup as String] as? String
    }
    set {
      if let accessGroup = newValue {
        self.attributes[kSecAttrAccessGroup as String] = accessGroup as AnyObject?
      } else {
        self.attributes.removeValue(forKey: kSecAttrAccessGroup as String)
      }
    }
  }
  /**
   *  Set true to sync the item to the iCloud Keychain.
   *
   *  - Note: Default is false.
   */
  open var synchronizable: Bool? {
    get {
      return self.attributes[kSecAttrSynchronizable as String] as? Bool
    }
    set {
      if let doSync = newValue {
        self.attributes[kSecAttrSynchronizable as String] = (doSync) ? kCFBooleanTrue : kCFBooleanFalse
      } else {
        self.attributes.removeValue(forKey: kSecAttrSynchronizable as String)
      }
    }
  }
  /**
   *  Description attribute key.
   *
   *  A user-visible string describing this kind of item (for example, "Disk image password").
   */
  open var description: String? {
    get {
      return self.attributes[kSecAttrDescription as String] as? String
    }
    set {
      if let description = newValue {
        self.attributes[kSecAttrDescription as String] = description as AnyObject?
      } else {
        self.attributes.removeValue(forKey: kSecAttrDescription as String)
      }
    }
  }
  /**
   *  Comment attribute key.
   *
   *  Contains the user-editable comment for this item.
   */
  open var comment: String? {
    get {
      return self.attributes[kSecAttrComment as String] as? String
    }
    set {
      if let comment = newValue {
        self.attributes[kSecAttrComment as String] = comment as AnyObject?
      } else {
        self.attributes.removeValue(forKey: kSecAttrComment as String)
      }
    }
  }
  /**
   *  Label attribute key.
   *
   *  Contains the user-visible label for this item.
   */
  open var label: String? {
    get {
      return self.attributes[kSecAttrLabel as String] as? String
    }
    set {
      if let label = newValue {
        self.attributes[kSecAttrLabel as String] = label as AnyObject?
      } else {
        self.attributes.removeValue(forKey: kSecAttrLabel as String)
      }
    }
  }
  /**
   *  Account attribute key.
   *
   *  Contains an account name. Items of class Generic Password and Internet Password have this attribute.
   */
  open var account: String? {
    get {
      return self.attributes[kSecAttrAccount as String] as? String
    }
    set {
      if let account = newValue {
        self.attributes[kSecAttrAccount as String] = account as AnyObject?
      } else {
        self.attributes.removeValue(forKey: kSecAttrAccount as String)
      }
    }
  }
  /**
   *  Service attribute key.
   *
   *  Represents the service associated with this item. Items of class Generic Password have this attribute.
   */
  open var service: String? {
    get {
      return self.attributes[kSecAttrService as String] as? String
    }
    set {
      if let service = newValue {
        self.attributes[kSecAttrService as String] = service as AnyObject?
      } else {
        self.attributes.removeValue(forKey: kSecAttrService as String)
      }
    }
  }
  /**
   *  Security domain attribute key.
   *
   *  Represents the Internet security domain. Items of class Internet Password have this attribute.
   */
  open var securityDomain: String? {
    get {
      return self.attributes[kSecAttrSecurityDomain as String] as? String
    }
    set {
      if let securityDomain = newValue {
        self.attributes[kSecAttrSecurityDomain as String] = securityDomain as AnyObject?
      } else {
        self.attributes.removeValue(forKey: kSecAttrSecurityDomain as String)
      }
    }
  }
  /**
   *  Server attribute key.
   *
   *  Contains the server's domain name or IP address. Items of class Internet Password have this attribute.
   */
  open var server: String? {
    get {
      return self.attributes[kSecAttrServer as String] as? String
    }
    set {
      if let server = newValue {
        self.attributes[kSecAttrServer as String] = server as AnyObject?
      } else {
        self.attributes.removeValue(forKey: kSecAttrServer as String)
      }
    }
  }
  /**
   *  Protocol attribute key.
   *
   *  Denotes the protocol for this item. Items of class Internet Password have this attribute.
   *
   *  - SeeAlso: KeychainProtocolType for possible values.
   */
  open var internetProtocol: KeychainProtocolType? {
    get {
      if let internetProtocol = self.attributes[kSecAttrProtocol as String] as? String {
        return KeychainProtocolType(rawValue: internetProtocol)
      }
      
      return nil
    }
    set {
      if let internetProtocol = newValue {
        self.attributes[kSecAttrProtocol as String] = internetProtocol.rawValue as String as AnyObject?
      } else {
        self.attributes.removeValue(forKey: kSecAttrProtocol as String)
      }
    }
  }
  /**
   *  Path attribute key.
   *
   *  Represents a path, typically the path component of the URL. Items of class Internet Password have this attribute.
   */
  open var path: String? {
    get {
      return self.attributes[kSecAttrPath as String] as? String
    }
    set {
      if let path = newValue {
        self.attributes[kSecAttrPath as String] = path as AnyObject?
      } else {
        self.attributes.removeValue(forKey: kSecAttrPath as String)
      }
    }
  }
  /**
   *  The OSStatus code returned.
   */
  open var OSStatusCode: OSStatus?
  
  // MARK: - Read Only Properties
  
  /**
   *  The item class value (read only)
   *  - Note: This property is set upon initialization.
   */
  open fileprivate(set) var itemClass: String
  /**
   *  The attributes dictionary (read only).
   */
  open fileprivate(set) var attributes: [String: AnyObject] = [:]
  /**
   *  The search query (read only).
   *
   *  - Note: You can add items with the load(_:) method.
   */
  open fileprivate(set) var searchQuery: [String: AnyObject] = [
    kSecAttrSynchronizable as String: kSecAttrSynchronizableAny
  ]
  
  // MARK: - Init
  
  /**
   *  Creates an instance of the Keychain Item structure.
   *
   *  - Parameter withItemClass: The item class of the Keychain item. A KeychainItemClass enum.
   */
  public init(itemClass: KeychainItemClass) {
    self.itemClass = itemClass.rawValue
    self.configure()
  }
  /**
   *  Creates an instance of the Keychain Item structure.
   *
   *  - Parameter withItemClass: The item class of the Keychain item. A KeychainItemClass enum.
   *  - Parameter attributeDictionary: The item's attributes. Pass the search result dictionary returned by the ```SecItemCopyMatching(_:result:)``` method.
   *
   *  - Important: To create a new KeychainItem, call ```init(withItemClass:``` instead. Use this method only when manually retrieving an item by using ```SecItemCopyMatching(_:result:)```, or the Keychain struct function ```load(_:)```:
   *
   *  ```swift
   *  let query: [String: AnyObject] = [...]
   *  let dict = Keychain.load(query)
   *  let item = KeychainItem(attributeDictionary: dict as! [String : AnyObject])
   *  ```
   */
  public init(itemClass: KeychainItemClass, attributeDictionary: [String: AnyObject]) {
    self.itemClass = itemClass.rawValue
    self.attributes = attributeDictionary
    self.configure()
  }
  /**
   *  Creates an instance of the Keychain Item structure.
   *
   *  - Parameter withItemClass: The item class of the Keychain item. A KeychainItemClass enum.
   *  - Parameter attributeDictionary: The item's attributes. Pass the search result dictionary returned by the ```SecItemCopyMatching(_:result:)``` method.
   *
   *  - Important: To create a new KeychainItem, call ```init(withItemClass:``` instead. Use this method only when manually retrieving an item by using ```SecItemCopyMatching(_:result:)```, or the Keychain struct function ```load(_:)```:
   *
   *  ```swift
   *  let query: [String: AnyObject] = [...]
   *  let dict = Keychain.load(query)
   *  let item = KeychainItem(attributeDictionary: dict as! [String : AnyObject])
   *  ```
   */
  public init(attributeDictionary: [String: AnyObject]) {
    self.itemClass = attributeDictionary[kSecClass as String] as? String ?? KeychainItemClass.genericPassword.rawValue
    self.attributes = attributeDictionary
    self.configure()
  }
  
  fileprivate func configure() {
    self.searchQuery[kSecClass as String] = self.itemClass as String as AnyObject?
    
    if let acc = self.account {
      self.searchQuery[kSecAttrAccount as String] = acc as AnyObject?
    }
    
    if let ser = self.service {
      self.searchQuery[kSecAttrService as String] = ser as AnyObject?
    }
  }
  
  // MARK: - Edit Methods
  
  /**
   *  Save the item to the Keychain.
   *
   *  - Parameter value: The value to save (optional).
   *
   *  - Note: Before saving, the properties *account* and *service* should be set. If you do not pass a value to when calling this method, the latest value will be saved.
   */
  open func save(_ value: String? = nil) -> Bool {
    if let value = value {
      self.value = value
    }
    
    if self.attributes.isEmpty || self.value == nil {
      return false
    }
    
    self.attributes[kSecClass as String] = self.itemClass as AnyObject?
    
    let result = Keychain.save(self.attributes)
    self.OSStatusCode = result.statusCode
    
    return result.success
  }
  /**
   *  Update the item in the Keychain.
   *
   *  - Parameter value: The value to save (optional).
   *
   *  - Note: This function will update all of the attributes of the item. If you do not pass a value to when calling this method, the latest value will be saved.
   */
  open func update(_ value: String? = nil) -> Bool {
    if let value = value {
      self.value = value
    }
    
    self.configure()
    
    let result = Keychain.update(self.searchQuery, attributes: self.attributes)
    self.OSStatusCode = result.statusCode
    
    return result.success
  }
  
  /**
   *  Load the item from the Keychain.
   *
   *  - Parameter withQuery: Add extra attributes to the search query. If set nil, the search query will consist of amongst other keys, the service and account keys.
   *
   *  - Note: The account and service attributes must be set before loading.
   */
  open func load(_ query: [String: AnyObject]? = nil) -> Bool {
    var searchQuery = self.searchQuery
    searchQuery[kSecMatchLimit as String] = kSecMatchLimitOne
    searchQuery[kSecReturnData as String] = kCFBooleanTrue
    searchQuery[kSecReturnAttributes as String] = kCFBooleanTrue
    
    if let queryItems = query {
      for (key, value) in queryItems {
        searchQuery[key] = value
      }
    }
    
    let result = Keychain.load(searchQuery)
    
    if let data = result.data as? [String: AnyObject] {
      self.attributes = data
    }
    
    self.OSStatusCode = result.statusCode
    
    return result.success
  }
  
}
