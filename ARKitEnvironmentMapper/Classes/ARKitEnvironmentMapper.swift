import CoreGraphics
import QuartzCore
import MetalKit
import ARKit

public class ARKitEnvironmentMapper {

  private let width: Int
  private let height: Int

  private var xFov: Float!
  private var yFov: Float!

  private let metalManager: MetalMemoryManager

  private var currentFrameInfo: FrameInfo?

  private var coordinateConversionTexture: MTLTexture!
  private var environmentMapTexture: MTLTexture!

  private let updatesPerSecond = 10
  private var lastUpdateTime: CFTimeInterval = 0

  private(set) public var isMapping: Bool

  /**
   Returns an `ARKitEnvironmentMapper` object with the image whose name is `imageName` as the base environment map.

   Mapping is inactive by default, so `startMapping()` needs to be called to start mapping the camera feed to the environment map. It is advised to call it after a couple of seconds after the `ARSession` starts to avoid any wrong mappings during the initialization of the app.

   - parameter imageName: The name of the image to be set as the base environment map. The image must have an aspect ratio of 2:1 and is advised to have multitudes of 32 as dimensions.
   - returns: The `ARKitEnvironmentMapper` object with a base environment map, or `nil` if there is no such image with the name `imageName` or the image does not conform to a 2:1 aspect ratio or the device does not support the Metal framework.
   */
  public init?(withImageName imageName: String) {
    let im = UIImage(named: imageName, in: Bundle.main, compatibleWith: nil)
    guard let image = im else {
      print("Can not find image with name: \(imageName)")
      return nil
    }

    height = Int(image.size.height)
    width = Int(image.size.width)

    guard width == height * 2 else {
      print("Image dimensions do not match the 2:1 ratio required by SceneKit.")
      return nil
    }

    guard let mtlManager = MetalMemoryManager(withMapHeight: height) else {
      return nil
    }

    metalManager = mtlManager

    isMapping = false

    setupEnvironmentMapTexture(withDefaultEnvironmentMapImage: image.cgImage)
    setupCoordinateConversionTexture()
  }

  /**
   Returns an `ARKitEnvironmentMapper` object with the image whose name is `imageName` as the base environment map.

   Mapping is inactive by default, so `startMapping()` needs to be called to start mapping the camera feed to the environment map. It is advised to call it after a couple of seconds after the `ARSession` starts to avoid any wrong mappings during the initialization of the app.

   - parameter height: The height of the base environment map. The width will be `2 * height` as the environment map needs to have a 2:1 aspect ratio. It is advised to provide a multitude of 32 as the height.
   - parameter color: The color to fill the base environment map with.
   - returns: The `ARKitEnvironmentMapper` object with a base environment map, or `nil` if the device does not support the Metal framework.
   */
  public init?(withMapHeight height: Int, withDefaultColor color: UIColor) {
    self.height = height
    self.width = height * 2

    guard let mtlManager = MetalMemoryManager(withMapHeight: height) else {
      return nil
    }

    metalManager = mtlManager

    isMapping = false

    setupEnvironmentMapTexture(withDefaultEnvironmentMapImage: nil, orWithDefaultTextureColor: color)
    setupCoordinateConversionTexture()
  }

  private func setupEnvironmentMapTexture(withDefaultEnvironmentMapImage cgImage: CGImage? = nil,
                                          orWithDefaultTextureColor color: UIColor? = nil) {
    if let cgImage = cgImage {
      environmentMapTexture = metalManager.newWritableTexture(fromCGImage: cgImage)
    } else if let color = color {
      environmentMapTexture = metalManager.newWritableTexture(withHeight: height, withColor: color)
    } else {
      fatalError("Wrong parameters provided to initializer.")
    }
  }

  private func shouldUpdate() -> Bool {
    let currentTime = CACurrentMediaTime()
    return isMapping && currentTime - lastUpdateTime > (1.0 / Double(updatesPerSecond))
  }

  private func setupCoordinateConversionTexture() {
    // 8 bits per component is not precise for us to convert spherical coordinates to Cartesian vectors,
    // however iOS does not support floating-point components as of now. PixelFormats.swift contains
    // RGBA64 and RGBAFloat but they can not be used yet. If these two formats are ever supported on iOS,
    // those two would yield much better conversion precision. For more on the matter:
    // https://developer.apple.com/library/content/documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/dq_context/dq_context.html
    guard let cgContext = CGContext(data: nil,
                                    width: width,
                                    height: height,
                                    bitsPerComponent: RGBA32.bitsPerComponent,
                                    bytesPerRow: RGBA32.bytesPerRow(width: width),
                                    space: CGColorSpaceCreateDeviceRGB(),
                                    bitmapInfo: RGBA32.bitmapInfo) else {
                                      print("Unable to create CGContext")
                                      return
    }

    guard let buffer = cgContext.data else {
      print("Unable to create textures")
      return
    }
    let pixelBuffer = buffer.bindMemory(to: RGBA32.self, capacity: width * height)
    let heightFloat = Float(height)
    let widthFloat = Float(width)
    for i in 0 ..< height {
      let theta = Float.pi * Float(i + 1) / heightFloat
      for j in 0 ..< width {
        let phi = 2 * Float.pi * Float(j + 1) / widthFloat
        // flip the components because of the Cartesian coordinate conventions
        let x = UInt8(((sin(theta) * cos(phi) + 1.0) / 2.0) * 255)
        let z = UInt8(((sin(theta) * sin(phi) + 1.0) / 2.0) * 255)
        let y = UInt8(((cos(theta) + 1) / 2.0) * 255)
        let offset = width * i + j
        pixelBuffer[offset] = RGBA32(red: x, green: y, blue: z, alpha: 255)
      }
    }

    guard let coordinateConversionImage = cgContext.makeImage() else {
      return
    }
    coordinateConversionTexture = metalManager.newReadableTexture(fromCGImage: coordinateConversionImage)
  }

  /**
   Updates the generated environment map using the current seen image and the orientation of the device.

   You can use this method inside `ARSCNViewDelegate`'s `session(_: ARSession, didUpdate: ARFrame)` method regardless of the preferred FPS, as the frequency of this method is limited to at most 10 by default. The frequency will be customizable in a future release.

   - parameter frame: Frame information to update the environment map with.
   */
  public func updateMap(withFrame frame: ARFrame) {
    guard shouldUpdate() else {
      return
    }
    lastUpdateTime = CACurrentMediaTime()

    let cameraTransform = SCNMatrix4(frame.camera.transform)
    let cameraForward = SCNVector3(cameraTransform.m31, cameraTransform.m32, cameraTransform.m33) * -1
    let cameraUp = SCNVector3(cameraTransform.m21, cameraTransform.m22, cameraTransform.m23)
    let cameraLeft = SCNVector3(cameraTransform.m11, cameraTransform.m12, cameraTransform.m13) * -1

    if xFov == nil {
      let imageResolution = frame.camera.imageResolution
      let intrinsics = frame.camera.intrinsics
      xFov = 2 * atan(Float(imageResolution.width) / (2 * intrinsics[0, 0]))
      yFov = 2 * atan(Float(imageResolution.height) / (2 * intrinsics[1, 1]))
    }

    let halfXFov = xFov / 2
    let halfYFov = yFov / 2
    // 0: bottom left, 1: bottom right, 2: top right, 3: top left
    let rotations = [(halfXFov, halfYFov), (-halfXFov, halfYFov), (-halfXFov, -halfYFov), (halfXFov, -halfYFov)]
    let frustum = rotations.map { (rotX, rotY) -> SCNVector3 in
      let rotatedLeft = cameraLeft.rotate(around: cameraUp, by: rotX)
      let rotatedForward = cameraForward.rotate(around: cameraUp, by: rotX)
      return rotatedForward.rotate(around: rotatedLeft, by: rotY)
    }

    if let currentLightIntensity = frame.lightEstimate?.ambientIntensity {
      ImageConverter.correctIntensity(of: frame.capturedImage, with: currentLightIntensity)
    }
    guard let currentFrameTexture = metalManager.newReadableTexture(fromCVPixelBuffer: frame.capturedImage) else {
      return
    }
    currentFrameInfo = FrameInfo(frustum, cameraForward, Float(currentFrameTexture.width), Float(currentFrameTexture.height))

    metalManager.updateEnvironmentMapTask(currentFrame: currentFrameTexture,
                                          convertingCoordinatesWith: coordinateConversionTexture,
                                          environmentMap: environmentMapTexture,
                                          info: &currentFrameInfo)
  }

  /**
   Returns the current generated environment map in the requested format. Default format is `.mtlTexture`.

   - important: `.mtlTexture` format currently does not work because of an Apple bug. This method will return the environment map as a `MTLTexture`, however setting it as the environment map of your ARSCNView will have no effect.
   - parameter format: the format in which the generated environment map should be returned. Valid options are `.mtlTexture`, `.cgImage` and `.uiImage`.
   - returns: the environment map in the requested format.
   */
  public func currentEnvironmentMap(as format: EnvironmentMapType = .mtlTexture) -> Any? {
    switch format {
    case .mtlTexture:
      return environmentMapTexture
    case .cgImage:
      return ImageConverter.convertToCGImage(from: environmentMapTexture)
    case .uiImage:
      if let cgImage = ImageConverter.convertToCGImage(from: environmentMapTexture) {
        return UIImage(cgImage: cgImage)
      } else {
        return nil
      }
    }
  }

  /**
   Starts ARKitEnvironmentMapper's updates.
   */
  public func startMapping() {
    isMapping = true
  }

  /**
   Stops ARKitEnvironmentMapper's updates.
   */
  public func stopMapping() {
    isMapping = false
  }

  /**
   Resets the environment map generated by ARKitEnvironmentMapper.

   If both parameters are provided, `cgImage` will be used.
   - parameter cgImage: `CGImage` to set as the base environment map.
   - parameter color: `UIColor` to fill the base environment map with.
   */
  private func reset(withDefaultEnvironmentMapImage cgImage: CGImage? = nil,
                    orWithDefaultTextureColor color: UIColor? = nil) {
    lastUpdateTime = CACurrentMediaTime()
    setupEnvironmentMapTexture(withDefaultEnvironmentMapImage: cgImage,
                               orWithDefaultTextureColor: color)
  }

}

public enum EnvironmentMapType {
  case mtlTexture
  case cgImage
  case uiImage
}
