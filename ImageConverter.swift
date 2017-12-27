class ImageConverter {

  private static let ciContext: CIContext = CIContext(options: nil)

//  private static let avgLightIntensity: CGFloat = 2500.0
//  private static let maxLightIntensity: CGFloat = 6000.0
//  private static let minLightIntensity: CGFloat = 0.0

  private static var maxLightIntensity: CGFloat = 0.0
  private static var minLightIntensity: CGFloat = 0.0

  private static let exposureAdjustFilter = CIFilter(name: "CIExposureAdjust")!

  static func convertToCGImage(from pixelBuffer: CVPixelBuffer) -> CGImage? {
    let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
    let cgImage = ciContext.createCGImage(ciImage, from: CGRect(x: 0,
                                                                y: 0,
                                                                width: CVPixelBufferGetWidth(pixelBuffer),
                                                                height: CVPixelBufferGetHeight(pixelBuffer)))
    return cgImage
  }

  static func convertToCGImage(from texture: MTLTexture) -> CGImage? {
    guard texture.pixelFormat == .bgra8Unorm_srgb else {
      return nil
    }

    guard let ciImage = CIImage(mtlTexture: texture, options: nil) else {
      return nil
    }
    let correctedImage = ciImage.transformed(by: CGAffineTransform(scaleX: 1, y: -1))
    return ciContext.createCGImage(correctedImage, from: correctedImage.extent)
  }

  static func correctIntensity(of pixelBuffer: CVPixelBuffer, with estimatedIntensity: CGFloat) {
    let inputImage = CIImage(cvPixelBuffer: pixelBuffer)
//    let ev  = normalize(value: estimatedIntensity, between: minLightIntensity, and: maxLightIntensity, withMid: avgLightIntensity)
    maxLightIntensity = max(maxLightIntensity, estimatedIntensity)
    let ev = (1 / 2) * (maxLightIntensity - estimatedIntensity) / maxLightIntensity
    exposureAdjustFilter.setValue(inputImage, forKey: kCIInputImageKey)
    exposureAdjustFilter.setValue(ev, forKey: kCIInputEVKey)
    if let outputImage = exposureAdjustFilter.outputImage {
      ciContext.render(outputImage, to: pixelBuffer)
    }
  }

}
