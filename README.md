



![logo](https://github.com/manuelvrhovac/resources/blob/master/QuickPickerHeader.jpg?raw=true)

Use `QuickPicker` to pick media from users Photos library, much like `UIImagePickerController`. 

## Contents

- [Requirements](#requirements)
- [Features](#features)
- [Workflow](#workflow)
- [Usage](#usage)
- [Dependencies](#dependencies)
- [Installation](#installation)
- [License](#license)

## Requirements

- iOS 10.0+
- Xcode 10.0+
- Swift 4.2+
- RxSwift and KVFetcher libraries

## Features

**Pick single or multiple items:**
- Images, videos or both
- Limit number of items 
- Swipe and crawl down and up
- Undo up to 20 steps

**Better Navigation:**
-  See attributes of items (favorite, video duration, slo-mo...)
- Jump to specific collection(s) in 1-2 taps using tab bar

**Review Screen:**
- Preview selected images and videos before continuing
- Scroll quickly through items (if more than 30)
- Remove items

<a id="workflow"></a>
## Workflow:


![logo](https://github.com/manuelvrhovac/resources/blob/master/QuickPickerSingleMultiple.jpg?raw=true)



## Usage 
<a id="usage"></a>


#### Pick single image:
```swift

var config = QuickPicker.Config(selectionMode: .single, allowedMedia: .images)

let quickPicker = QuickPicker(configuration: config, preselected: nil){ quickPicker, result in
    quickPicker.dismiss(animated: true)
    switch result {
    case .finished(let assets):
        print("Picked \(assets.count) assets")
    case .canceled:
        print("Canceled")
    }
}

present(quickPicker, animated: true, completion: nil)

```

> **Note:** QuickPicker result is an array of PHAsset objects and not full size images or thumbnails.

To pick multiple items and to pick both images and videos, change the config to this:


```swift

var config = QuickPicker.Config(selectionMode: .multiple(max: 30), allowedMedia: [.images, .videos])
...
```

#### All configuration options:

- **allowedMedia**: OptionSet - What media is allowed to be picked (image/video/both).
- **picking**: Selection mode - can be single or multiple (with limit or unlimited).
- **customTabKinds**: Options that appear in the segmented control (default: Recently Added, favorites, My Albums, iCloud albums, smartAlbums)
- **needsConfirmation**: Should display a popup where user can review picked photo(s)
- **showsLimit**: If limited count, display how many photos remaining or don't
- **preselected**: Assets that should be selected in advance
- **presentFirstOfferMoreLater**: Similar to how WhatsApp works - start as picking a single image/video and then offer the option to continue picking multiple.
- **maximumThumbnailSize**: Dimension of item thumbnail in collection view. It will be resized under this value to fill the screen width. Default: [.phone: 100, .pad: 130]
- **tintColor**: The tintColor of the picker (nil = usual iOS blue)

### Defining custom Tabs

![logo](https://github.com/manuelvrhovac/resources/blob/master/QuickPickerTabs.jpg?raw=true)

Tab bar (segmented control) on the bottom is used to jump to specific collection (like Recently Added or Favorites), or to group of collections (like iCloud Shared or Smart Albums). The tabs that  appear in picker are defined in `.config.customTabKinds`:
```swift

var config = QuickPicker.Config(selectionMode: .single, allowedMedia: .images)
config.tabKinds = [.recentlyAdded, .favorites, .groupRegular, .groupSmart]

```

#### Possible TabKinds:
- Grouped (album list):
- **groupRegular** - My Albums
- **groupShared** - iCloud Shared Albums
- **groupSmart** - Smart Albums (like the ones below)
- Single (item list):
- **recentlyAdded**
- **userLibrary** (Camera Roll)
- **favorites**
- **videos**
- **screenshots**
- **selfPortraits** (Selfies)
- **panoramas**
...

## Dependencies

- RxSwift (5.0.1) -  https://github.com/ReactiveX/RxSwift
- KVFetcher (0.9.1) - my own - https://github.com/manuelvrhovac/KVFetcher

Both should be automatically added to your project if you install QuickPicker using CocoaPods (Podfile). I'm not sure how this should play out if you already use some version of RxSwift or don't plan on using CocoaPods.

## Installation

### CocoaPods

[CocoaPods](http://cocoapods.org) is a dependency manager for Cocoa projects. To integrate QuickPicker into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
platform :ios, '10.0'
use_frameworks!

target '<Your Target Name>' do
pod 'QuickPicker', '~> 0.9.2'
end
```

Then run `pod install` command inside Terminal.

### Carthage

[Carthage](https://github.com/Carthage/Carthage) is a decentralized dependency manager that builds your dependencies and provides you with binary frameworks. To integrate QuickPicker into your Xcode project using Carthage, specify it in your `Cartfile`:

```ogdl
github "manuelvrhovac/QuickPicker" ~> 0.9.2
```

Run `carthage update` to build the framework and drag the built `QuickPicker.framework` into your Xcode project.

### Manually

If you prefer not to use either of the aforementioned dependency managers, you can integrate QuickPicker into your project manually.


## License

QuickPicker is released under the MIT license. See LICENSE for details.

