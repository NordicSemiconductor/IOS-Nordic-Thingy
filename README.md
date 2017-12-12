Thingy SDK for iOS

[![Version](http://img.shields.io/cocoapods/v/IOSThingyLibrary.svg)](http://cocoapods.org/pods/IOSThingyLibrary)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
## Installation
**For Cocoapods(Swift):**
- Create/Update your **Podfile** with the following contents
```
target 'YourAppTargetName' do
    use_frameworks!
    pod 'IOSThingyLibrary', '~> 1.3.1'
end
```
- Install dependencies
```
pod install
```
- Open the newly created `.xcworkspace`
- Import the library to any of your classes by using `import IOSThingyLibrary` and begin working on your project

**For Carthage:**
- Create a new **Cartfile** in your project's root with the following contents
```
github "NordicSemiconductor/NordicSemiconductor/IOS-Nordic-Thingy" ~> 1.3.1
```

- Build with carthage
 
```
carthage update --platform iOS
```
- Carthage will build the **IOSThingyLibrary.framework**, **iOSDFULibrary.framework** and **Zip.framework** files in **Carthag/Build/**, you may now copy all those files to your project and use the library, additionally, carthage also builds **\*.dsym** files if you need to resymbolicate crash logs. you may want to keep those files bundled with your builds for future use.
---
### Trying with the example app
This library comes with a very powerful opensource example app that you may download on the app store or try it directly using cocoapods, to try the Thingy App right now, go to your favorite terminal and type:

    pod try IOSThingyLibrary

Xcode will launch with the example app, simply build and run!

---
### Requirements
**Note**: This Library is built with Swift 4.0, even though Obj-C is compatible out of the box, we prefer to put all our focus forward into Swift 4.0 and above.
- A Thingy Device
- Xcode: Xcode 9 and above support Swift 4.0
- iOS 8.0 and above
    - iPhone compatibility:
        - iPhone 4s and above
    - iPad compatibility:
        - 3rd generation iPad and above
        - iPad Mini and above
        - iPad Air and above
        - iPad pro
    - iPod compatibility:
        - 5th Generation iPod and above
---
