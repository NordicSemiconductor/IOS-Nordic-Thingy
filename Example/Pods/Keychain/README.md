# Keychain

[![CI Status](http://img.shields.io/travis/pkrll/Keychain.svg?style=flat)](https://travis-ci.org/pkrll/Keychain)
[![Version](https://img.shields.io/cocoapods/v/Keychain.svg?style=flat)](http://cocoapods.org/pods/Keychain)
[![License](https://img.shields.io/cocoapods/l/Keychain.svg?style=flat)](http://cocoapods.org/pods/Keychain)
[![Platform](https://img.shields.io/cocoapods/p/Keychain.svg?style=flat)](http://cocoapods.org/pods/Keychain)
[![Documentation](https://img.shields.io/cocoapods/metrics/doc-percent/Keychain.svg?style=flat)](http://cocoadocs.org/docsets/Keychain/)

**Keychain** is an easy-to-use wrapper class for using the system keychain and offers a simple interface to store user credentials with more advance features available.

**Features**
* Quick methods for saving to, loading and deleting from the keychain.
* Basic save, load and delete methods allowing for advanced query/attributes dictionaries.
* **Keychain** also includes the ```KeychainItem``` class, that allows for saving and loading items from the keychain as instances of the class, making it even easier to use the system keychain. (See below for more information).

## Quick usage
There are several ways to go about to save an item to the keychain. The most basic is just calling the class function ```save(_:forKey:)```. This will save the specified value to the keychain, that can later be retrieved by using the value passed to the ```forKey``` parameter.
```swift
// To save some value to the keychain use:
Keychain.save("some value", forKey: "Some key")

// You can retrieve it by using the same key:
let data = Keychain.load("Some Key")
print(data) 
// Prints "some value"
```
Deleting the item from the keychain follows the same logic:
```swift
if Keychain.delete("Some Key") {
    // Success!
}
```
## Advanced usage
If you need to create custom attribute dictionaries (for example, for setting the service and/or account attributes yourself instead of letting the wrapper handle it), **Keychain** also allows for more advanced operations.

(_Note: The advande save/load/delete methods require you to create the attribute/search dictionaries. Please consult the [Keychain Service Reference](https://developer.apple.com/library/ios/documentation/Security/Reference/keychainservices/) for more information._)
##### Save Example (advanced)
The advanced ```save(_:)``` function returns a tuple with two members: (success: Bool, statusCode: OSStatus).
```swift
let value = "Some value"

let attributes: [String: AnyObject] = [
  kSecClass as String       : kSecClassGenericPassword as String,
  kSecAttrAccount as String : "Some Account",
  kSecAttrService as String : "Some Service",
  kSecValueData as String   : value.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!
]

let result = Keychain.save(attributes)

if result.success {
  // Success!
} else {
  // Failure!
  // Check OSStatus
  print(result.statusCode)
}
```
##### Load Example (advanced)
The advanced ```load(_:)``` function will return a tuple with three members: ```(success: Bool, data: NSData?, statusCode: OSStatus)```.
```swift
let query: [String: AnyObject] = [
  kSecClass as String       : kSecClassGenericPassword as String,
  kSecMatchLimit as String  : kSecMatchLimitOne,
  kSecReturnData as String  : kCFBooleanTrue,
  kSecAttrService as String : "Some Service",
  kSecAttrAccount as String : "Some Account"
]

let result = Keychain.load(query)

if result.success {
  let string = String(data: result.data as! NSData, encoding: NSUTF8StringEncoding)
  print(string) // Prints "Some value"
} else {
  print(result.statusCode)
  }
```
##### Delete Example (Advanced)
The advanced ```delete(_:)``` function returns a tuple with two members: (success: Bool, statusCode: OSStatus).
```swift
let query: [String: AnyObject] = [
  kSecClass as String       : kSecClassGenericPassword as String,
  kSecAttrService as String : "Some Service",
  kSecAttrAccount as String : "Some Account"
]

let result = Keychain.delete(query)

if result.success {
  print(result.success)
} else {
  print(result.statusCode)
}
```
## Using KeychainItem (Beta)
**Keychain** includes the class ```KeychainItem``` that hides away a lot of the ugliness that you'd otherwise have to handle when working with Keychain Services. 

Instead of definining attributes and search dictionaries, ```KeychainItem``` offers a more intuitive, OOP-way of using Keychain Services.

(_Note: The KeychainItem class is still in development, and works best/only with items of classes kSecClassGenericPassword and kSecClassInternetPassword_).
##### Save Example (KeychainItem)
```swift
let kItem = KeychainItem(withItemClass: KeychainItemClass.GenericPassword)
kItem.account = "pkrll"
kItem.service = "Github.com"
kItem.label = "Github"
kItem.value = "somePassword"
kItem.synchronizable = true

if kItem.save() {
  // Success!
} else {
  // Failure!!
  let statusCode = kItem.OSStatusCode
  print(statusCode)
}
```
##### Load Example (KeychainItem)
The below code shows how to load items as instances of ```KeychanItem``` as of today. (In future releases it should however be possible to load a single item by creating an instance of ```KeychainItem```, instead of creating a search dictionary).
```swift
let query: [String: AnyObject] = [
  kSecClass as String                 : KeychainItemClass.GenericPassword.rawValue as String,
  kSecMatchLimit as String            : kSecMatchLimitAll,
  kSecMatchCaseInsensitive as String  : kCFBooleanTrue,
  kSecReturnData as String            : kCFBooleanTrue,
  kSecReturnAttributes as String      : kCFBooleanTrue,
  kSecAttrSynchronizable as String    : kSecAttrSynchronizableAny
]

let items = KeychainItemFactory.load(query)
// Returns an array of KeychainItem objects ( [KeychainItem] )
```
##### Update Example (KeychainItem)
Use the ```update(_:)``` method to update the keychain item.
```swift
kItem.value = "A new value"

if kItem.update() {
  // Success
} else {
  print(kItem.OSStatusCode)
}
```
## Requirements
* iOS 8

## Installation
Keychain is available through [CocoaPods](http://cocoapods.org). To install it, simply add the following line to your Podfile:

```ruby
pod "Keychain"
```

## Author
Ardalan Samimi, ardalan@saturnfive.se

## License
Keychain is available under the MIT license. See the LICENSE file for more info.
