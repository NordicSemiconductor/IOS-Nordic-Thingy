Thingy SDK for iOS
---

#### About Project

Thingy SDK for iOS aims to ease managing, exploring, programming and developing applications on the Thingy platform.

#### Installation instructions

Thingy SDK will be available via Cocoapods and Carthage builds, the SDK is currently in development so it's not publicly available yet.
##### Cocoapods installation instructions:
 1) Create a Podfile in the root of your project with the Thingy pod dependency
 
        //Example podfile TBD
2) In your terminal run the `pod install` command

        $pod install
3) Cocoapods will generate a new workspace, you should close the current open project and use the newly created workspace and begin using the SDK!

##### Carthage installation instructions:

1) Setup your cartfile with the Thingy SDK as a denpendncy

        //Example cartfile contents TBD
        
2) Run the `cart update` command

        $carthage update --platform iOS

3) Other platforms are supported too, for example `macOS`, `tvOS`, `watchOS` and `all`

4) Carthage will generate a Build directory with a framework file inside

5) Copy the newly generated framework into your new project and begin using the SDK!

#### Using the SDK

 1) Install the SDK into your project with any tool of your choice, we currently support both `Carthage` and `Cocoapods`. see Installation instructions for an expample
 2) In your `AppDelegate`, initialize the Thingy SDK
 
        //Initialization example TBD
 3) Start interacting by finding a Thingy using the following code
 
        //Discovery Code example TBD
 
 4) After conneccting, you may query any of the sensor data as follows, let's read the temperature as an example
 
        //Sensor querying example TBD
#### Requirements

- A Thingy device.
- Xcode 8 or above.
- A device to run your compiled code on
  - iOS >= 8.0
  - Mac computers with Bluetooth 4 support (Can be found in the system report menu)

#### Example app

The Pod also bundles an example application that showcases many of the use cases for the Thingy, to get a hold of the example app, simply run `pod try ThingySDK` and an ew projcet will automatically launch in Xcode
