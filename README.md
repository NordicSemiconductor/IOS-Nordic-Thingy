[![Version](http://img.shields.io/cocoapods/v/IOSThingyLibrary.svg)](http://cocoapods.org/pods/IOSThingyLibrary)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

# Nordic Thingy:52 SDK for iOS

*IoT Sensor Kit*

## Compact multi-sensor prototyping platform
The **Nordic Thingy:52™** is an easy-to-use prototyping platform, designed to help in building prototypes and demos, without the need to build hardware or even write firmware. It is built around the nRF52832 Bluetooth 5 SoC.

All sensors and actuators can be configured over-the-air using Bluetooth Low Energy. It makes it possible to create demos and prototypes without starting from scratch. It connects to Bluetooth Low Energy-enabled smart phones, tablets, laptops and similar devices, and it sends/receives data from/to its sensors/actuators to an app or cloud. It includes an NFC antenna, and has 1 button and 1 RGB LED that simplifies input and output.

Read more: https://www.nordicsemi.com/Software-and-Tools/Development-Kits/Nordic-Thingy-52

## SDK and Sample application for iOS

This reposotory provides a library and a sample app for iOS that can be used to configure and use your Thingy:52 device.

The sample app may also be downloaded from iTunes: https://itunes.apple.com/us/app/nordic-thingy/id1187887000?mt=8

## Installation
**For Cocoapods(Swift):**
- Create/Update your **Podfile** with the following contents
```
target 'YourAppTargetName' do
    use_frameworks!
    pod 'IOSThingyLibrary', '~> 1.4.0'
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
github "NordicSemiconductor/NordicSemiconductor/IOS-Nordic-Thingy" ~> 1.4.0
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
**Note**: This Library is built with Swift 4.2, even though Obj-C is compatible out of the box, we prefer to put all our focus forward into Swift 4.2 and above.
- [Nordic Thingy:52](https://www.nordicsemi.com/Software-and-Tools/Development-Kits/Nordic-Thingy-52)
- Xcode: Xcode 10 and above support Swift 4.2
- iOS 9.0 and above
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
