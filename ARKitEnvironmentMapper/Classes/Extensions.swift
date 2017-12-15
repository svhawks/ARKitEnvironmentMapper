import SceneKit

extension SCNVector3 {

  static func * (left: SCNVector3, right: Float) -> SCNVector3 {
    return SCNVector3(left.x * right, left.y * right, left.z * right)
  }

  static func / (left: SCNVector3, right: Float) -> SCNVector3 {
    return left * (1 / right)
  }

  static func + (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    return SCNVector3(left.x + right.x, left.y + right.y, left.z + right.z)
  }

  static func - (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    return SCNVector3(left.x - right.x, left.y - right.y, left.z - right.z)
  }

  func dot(_ v: SCNVector3) -> Float {
    return x * v.x + y * v.y + z * v.z
  }

  func cross(_ v: SCNVector3) -> SCNVector3 {
    return SCNVector3(y * v.z - z * v.y,
                      z * v.x - x * v.z,
                      x * v.y - y * v.x)
  }

  func rotate(around axis: SCNVector3, by theta: Float) -> SCNVector3 {
    var v = self * cos(theta)
    v = v + (axis.cross(self)) * sin(theta)
    v = v + axis * (axis.dot(self)) * (1 - cos(theta))
    return v
  }

  func magnitude() -> Float {
    return sqrt(x * x + y * y + z * z)
  }

  func normalize() -> SCNVector3 {
    return self / magnitude()
  }
}

extension SCNVector4 {

  init(_ v: SCNVector3, _ n: Float) {
    self.init(v.x, v.y, v.z, n)
  }

}
