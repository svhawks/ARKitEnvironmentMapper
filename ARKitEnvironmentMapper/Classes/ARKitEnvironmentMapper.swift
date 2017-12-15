import CoreGraphics
import QuartzCore
import MetalKit
import ARKit

public class ARKitEnvironmentMapper {

  private let width: Int
  private let height: Int

  private var xFov: Float!
  private var yFov: Float!

  private let metalManager: MetalManager

  private var currentFrameInfo: FrameInfo?

  private var coordinateConversionTexture: MTLTexture!
  private var environmentMapTexture: MTLTexture!

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

    guard let mtlManager = MetalManager(withMapHeight: height) else {
      return nil
    }

    metalManager = mtlManager

    setupEnvironmentMapTexture(withDefaultEnvironmentMapImage: image.cgImage)
    setupCoordinateConversionTexture()
  }

  public init?(withMapHeight height: Int, withDefaultColor color: UIColor) {
    self.height = height
    self.width = height * 2

    guard let mtlManager = MetalManager(withMapHeight: height) else {
      return nil
    }

    metalManager = mtlManager

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
      let theta = Float.pi * (1 - Float(i + 1) / heightFloat)
      for j in 0 ..< width {
        let phi = 2 * Float.pi * Float(j + 1) / widthFloat
        let x = UInt8(((sin(theta) * cos(phi) + 1.0) / 2.0) * 255)
        let y = UInt8(((sin(theta) * sin(phi) + 1.0) / 2.0) * 255)
        let z = UInt8(((cos(theta) + 1) / 2.0) * 255)
        let offset = width * i + j
        pixelBuffer[offset] = RGBA32(red: x, green: y, blue: z, alpha: 255)
      }
    }

    guard let coordinateConversionImage = cgContext.makeImage() else {
      return
    }
    coordinateConversionTexture = metalManager.newReadableTexture(fromCGImage: coordinateConversionImage)
  }

  public func updateMap(withFrame frame: ARFrame, completionHandler: @escaping (MTLTexture) -> ()) {
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

    guard let currentFrameTexture = metalManager.newReadableTexture(fromCVPixelBuffer: frame.capturedImage) else {
      return
    }

    currentFrameInfo = FrameInfo(frustum, cameraForward, UInt(currentFrameTexture.width), UInt(currentFrameTexture.height))

    metalManager.updateEnvironmentMapTask(currentFrame: currentFrameTexture,
                                          convertingCoordinatesWith: coordinateConversionTexture,
                                          environmentMap: environmentMapTexture,
                                          info: &currentFrameInfo)

    completionHandler(environmentMapTexture)
  }

}
