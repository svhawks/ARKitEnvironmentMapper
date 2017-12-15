import CoreGraphics

struct RGBA32 {
  private var color: UInt32
  init(red: UInt8, green: UInt8, blue: UInt8, alpha: UInt8) {
    color = (UInt32(red) << 24)
    color = color | (UInt32(green) << 16)
    color = color | (UInt32(blue) << 8)
    color = color | (UInt32(alpha) << 0)
  }

  static let bitsPerComponent = 8
  static let bitmapInfo = CGImageAlphaInfo.noneSkipLast.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
  static func bytesPerRow(width: Int) -> Int{
    return width * MemoryLayout<RGBA32>.size
  }
}

struct RGBA64 {
  private var color: UInt64
  init(red: UInt16, green: UInt16, blue: UInt16, alpha: UInt16) {
    color = (UInt64(red) << 48)
    color = color | (UInt64(green) << 32)
    color = color | (UInt64(blue) << 16)
    color = color | (UInt64(alpha) << 0)
  }

  static let bitsPerComponent = 16
  static let bitmapInfo = CGImageAlphaInfo.noneSkipLast.rawValue | CGBitmapInfo.byteOrder16Little.rawValue
  static func bytesPerRow(width: Int) -> Int{
    return width * MemoryLayout<RGBA64>.size
  }
}

struct RGBAFloat {
  private var r: Float
  private var g: Float
  private var b: Float
  private var a: Float

  init(red: Float, green: Float, blue: Float, alpha: Float) {
    r = red
    g = green
    b = blue
    a = alpha
  }

  static let bitsPerComponent = 32
  static let bitmapInfo = CGImageAlphaInfo.noneSkipLast.rawValue | CGBitmapInfo.floatComponents.rawValue
  static func bytesPerRow(width: Int) -> Int{
    return width * MemoryLayout<RGBAFloat>.size
  }
}
