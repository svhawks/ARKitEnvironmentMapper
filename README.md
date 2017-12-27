# ARKitEnvironmentMapper

[![CI Status](http://img.shields.io/travis/svtek/ARKitEnvironmentMapper.svg?style=flat)](https://travis-ci.org/svtek/ARKitEnvironmentMapper)
[![Version](https://img.shields.io/cocoapods/v/ARKitEnvironmentMapper.svg?style=flat)](http://cocoapods.org/pods/ARKitEnvironmentMapper)
[![License](https://img.shields.io/cocoapods/l/ARKitEnvironmentMapper.svg?style=flat)](http://cocoapods.org/pods/ARKitEnvironmentMapper)
[![Platform](https://img.shields.io/cocoapods/p/ARKitEnvironmentMapper.svg?style=flat)](http://cocoapods.org/pods/ARKitEnvironmentMapper)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Installation

ARKitEnvironmentMapper is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'ARKitEnvironmentMapper'
```

## Usage

To initialize with a base environment map with an image asset named, for example, "room", use the following code:

```swift
let environmentMapper = ARKitEnvironmentMapper(withImageName: "room")
```

Note that the input image has to have a 2:1 aspect ratio.

Alternatively, you can initialize it with a height and a color:

```swift
let environmentMapper = ARKitEnvironmentMapper(withMapHeight: 512, withDefaultColor: .red)
```

To start the mapping process, call the `startMapping()` method. You should call this method a couple of seconds after running your `ARSession` in order not to get wrong mappings on your environment map.

To stop the mapping process, simply call `stopMapping()`.

To update the environment map with the current feed of the camera, you can use the following code in your class implementing `ARSessionDelegate`:

```swift
func session(_ session: ARSession, didUpdate frame: ARFrame) {
  environmentMapper.updateMap(withFrame: frame)
}
```

You can call `updateMap(withFrame:)` in `didUpdate` regardless of the preferred FPS, as it is not executed every frame. Its frequency is bound by the value `ARKitEnvironmentMapper.Options.updatesPerSecond` and the default value is 10 updates per second.

After mapping the environment for a while you can get the current generated environment map and set it as the environment map of your `ARSCNView` with the following code:

```swift
sceneView.scene.lightingEnvironment.contents = environmentMapper.currentEnvironmentMap(as: .cgImage)
```

__Note:__ The ideal way to set this should be to use `.mtlTexture` as input to bypass any image conversion and memory operation overhead. However, due to an Apple bug, setting a `MTLTexture` as the environment map currently has no effect. If you think this is not an Apple bug and you do have a solution, please don't hesitate to send a pull request.


## Author
| [<img src="https://avatars0.githubusercontent.com/u/4161376?s=460&v=4" width="100px;"/>](http://halil.kayim.me)   | [Halil Ibrahim Kayim](http://halil.kayim.me)<br/><br/><sub>Software Engineer @ [Surreal](http://surrealmarket.com)</sub><br/> [![Twitter][1.1]][1] [![Github][3.1]][3] [![LinkedIn][4.1]][4]|
| - | :- |

[1.1]: http://i.imgur.com/wWzX9uB.png (twitter icon without padding)
[2.1]: http://i.imgur.com/Vvy3Kru.png (dribbble icon without padding)
[3.1]: http://i.imgur.com/9I6NRUm.png (github icon without padding)
[4.1]: https://www.kingsfund.org.uk/themes/custom/kingsfund/dist/img/svg/sprite-icon-linkedin.svg (linkedin icon)

[1]: http://www.twitter.com/halileohalilei
[3]: http://www.github.com/halileohalilei
[4]: https://www.linkedin.com/in/halilkayim/

## License

ARKitEnvironmentMapper is available under the MIT license. See the LICENSE file for more info.
