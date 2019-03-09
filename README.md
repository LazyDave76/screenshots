
[![pub package](https://img.shields.io/pub/v/screenshots.svg)](https://pub.dartlang.org/packages/screenshots) 
[![Build Status](https://travis-ci.com/mmcc007/screenshots.svg?branch=master)](https://travis-ci.com/mmcc007/screenshots)

![alt text][demo]

[demo]: https://i.imgur.com/gkIEQ5y.gif "Screenshot with overlayed 
status bar and appended navigation bar placed in frame"  
Screenshot with overlaid status bar and appended navigation bar placed in a device frame.  

For an example of images generated with `Screenshots` on a live app in both stores see:  
[![GitErDone](https://play.google.com/intl/en_us/badges/images/badge_new.png)](https://play.google.com/store/apps/details?id=com.orbsoft.todo)
[![GitErDone](https://linkmaker.itunes.apple.com/en-us/badge-lrg.svg?releaseDate=2019-02-15&kind=iossoftware)](https://itunes.apple.com/us/app/giterdone/id1450240301)


See a demo of `Screenshots` in action:
[![Screenshots demo](https://i.imgur.com/V9VFSYb.png)](https://vimeo.com/317112577 "Screenshots demo - Click to Watch!")

For introduction to `Screenshots` see [article](https://medium.com/@nocnoc/automated-screenshots-for-flutter-f78be70cd5fd).

For information on automating `Screenshots` with a CI/CD tool see 
[fledge](https://github.com/mmcc007/fledge).

# Screenshots

`Screenshots` is a standalone command line utility and package for capturing Screenshots for 
Flutter. It will start the required android emulators and iOS simulators, run your screen 
capture tests on each emulator/simulator for each locale your app supports, process the images, and drop them off for Fastlane 
for delivery to both stores.

It is inspired by three tools from Fastlane:  
1. [Snapshots](https://docs.fastlane.tools/getting-started/ios/screenshots/)  
   This is used to capture screenshots on iOS using iOS UI Tests.
1. [Screengrab](https://docs.fastlane.tools/actions/screengrab/)  
   This captures screenshots on android using android espresso tests.
1. [FrameIt](https://docs.fastlane.tools/actions/frameit/)  
   This is used to place captured iOS screenshots in a device frame.

Since all three of these Fastlane tools do not work with Flutter, `Screenshots` combines key features of all three Fastlane tools into one tool. Plus, it is much easier to use! 

`Screenshots` features:
1. Captures screenshots from any iOS simulator or android emulator and processes images.
2. Frames screenshots in an iOS or android device frame.
3. The same Flutter integration test can be used across all simulators/emulators.  
   No need to use iOS UI Tests or Espresso.
4. Integrates with Fastlane's [deliver](https://docs.fastlane.tools/actions/deliver/) 
and [supply](https://docs.fastlane.tools/actions/supply/) for upload to respective stores.

# Usage

````
$ screenshots
````
Or, if using a config file other than the default 'screenshots.yaml':
````
$ screenshots -c <path to config file>
````

# Modifying tests for Screenshots
Capturing screenshots using this package is straightforward.

A special function is provided in
the `Screenshots` package that is called by the test each time you want to capture a screenshot. 
`Screenshots` will
then process the images appropriately during a `Screenshots` run.

To capture screenshots in your tests:
1. Include the `Screenshots` package in your pubspec.yaml's dev_dependencies section  
   ````yaml
     screenshots: ^<current version>
   ````
2. In your tests
    1. Import the dependencies  
       ````dart
       import 'package:screenshots/config.dart';
       import 'package:screenshots/capture_screen.dart';
       ````
    2. Create the config map at start of test  
       ````dart
            final Map config = Config().config;
       ````  
    3. Throughout the test make calls to capture screenshots  
       ````dart
           await screenshot(driver, config, 'myscreenshot1');
       ````
       
Note: make sure your screenshot names are unique across all your tests.

Note: to turn off the debug banner on your screens, in your integration test's main(), call:
````dart
  WidgetsApp.debugAllowBannerOverride = false; // remove debug banner for screenshots
````

# Configuration
To run `Screenshots` you need to setup a configuration file, `screenshots.yaml`:
````yaml
# Screen capture tests
# Note: flutter driver expects a pair of files eg, main1.dart and main1_test.dart
tests:
  - test_driver/main1.dart
  - test_driver/main2.dart

# Interim location of screenshots from tests
staging: /tmp/screenshots

# A list of locales supported by the app
locales:
  - de-DE
  - en-US

# A list of devices to emulate
devices:
  ios:
    - iPhone X
#    - iPhone 7 Plus
    - iPad Pro (12.9-inch) (2nd generation)
#   "iPhone 6",
#   "iPhone 6 Plus",
#   "iPhone 5",
#   "iPhone 4s",
#   "iPad Retina",
#   "iPad Pro"
  android:
    - Nexus 6P
#    - Nexus 5X

# Frame screenshots
frame: true
````
Note: emulators and simulators corresponding to the devices in your config file must be installed
on your test machine.

## Changing devices

If you want to know what your screens look like on different devices just change the list of devices in screenshots.yaml.

Make sure the devices
you select have supported screens and corresponding emulators/simulators.

_Within each class of ios and android device, multiple devices share the same screen size.
Devices are therefore organized by supported screens in a file called `screens.yaml`._

For each selected device:
1. Confirm device in present in 
[screens.yaml](https://github.com/mmcc007/screenshots/blob/master/lib/resources/screens.yaml).  
2. Add device to the list of devices in `screenshots.yaml`.  
3. Install an emulator or simulator for device.   
 
If changing devices seems tricky at first. Don't worry. `Screenshots` will validate the config file before running.

If you want to use a device that is not included in screens.yaml
, please create an [issue](https://github.com/mmcc007/screenshots/issues). Include
the name of the device and preferably the size of the screen in pixels 
(for example, Nexus 5X:1080x1920).

# Installation
To install `Screenshots` on the command line:
````bash
$ pub global activate screenshots
````
To upgrade, simply re-issue the command
````bash
$ pub global activate screenshots
````
Note: the `Screenshots` version should be the same for both the command line and package:
1. If upgrading the command line version of `Screenshots`, it is helpful to also upgrade
 the version of `Screenshots` in your pubspec.yaml.    
2. If upgrading `Screenshots` in your pubspec.yaml, you should also upgrade the command line version.    

## Dependencies
`Screenshots` depends on ImageMagick.  

Since screenshots are required by both Apple and Google stores, testing should be done on a Mac
(unless you are only testing for android).

````bash
brew update && brew install imagemagick
````

# Integration with Fastlane
Since `Screenshots` is intended to be used with Fastlane, after `Screenshots` completes, 
the images can be found in:
````
android/fastlane/metadata/android
ios/fastlane/screenshots
````
Images are in a format suitable for upload via [deliver](https://docs.fastlane.tools/actions/deliver/) 
and [supply](https://docs.fastlane.tools/actions/supply/).

Tip: Because Fastlane scripts are generally written for either iOS or Android (and not both), the easiest way to use Screenshots with Fastlane is to call Screenshots before making the two calls to Fastlane. Each call to Fastlane (for either iOS or Android) will then find the images in the appropriate place and can then upload the images to either the Apple or Google store consoles.
(For a live example of calling Fastlane for iOS and Android to upload screenshot images see Travis demo at [fledge](https://github.com/mmcc007/fledge).)

# Screenshots on Travis
To view `Screenshots` running with the example app on travis see:  
https://travis-ci.com/mmcc007/screenshots

To download the images generated by `Screenshots` during run on travis see:  
https://github.com/mmcc007/screenshots/releases/

# Issues and Pull Requests
[Issues](https://github.com/mmcc007/screenshots/issues) and 
[pull requests](https://github.com/mmcc007/screenshots/pulls) are welcome.

Your feedback is welcome and is used to guide where development effort is focused. So feel free to create as many issues and pull requests as you see fit. You should expect a timely and considered response.