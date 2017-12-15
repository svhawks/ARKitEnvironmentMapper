import SceneKit

struct FrameInfo {
  var p0: SCNVector4
  var p1: SCNVector4
  var p2: SCNVector4
  var p3: SCNVector4

  var cameraForward: SCNVector4

  var frameWidth: Float
  var frameHeight: Float
  var envMapWidth: UInt
  var envMapHeight: UInt

  init(_ frustum: [SCNVector3], _ forward: SCNVector3, _ width: UInt, _ height: UInt) {
    p0 = SCNVector4(frustum[0], 1.0)
    p1 = SCNVector4(frustum[1], 1.0)
    p2 = SCNVector4(frustum[2], 1.0)
    p3 = SCNVector4(frustum[3], 1.0)

    cameraForward = SCNVector4(forward, 1.0)

    envMapWidth = width
    envMapHeight = height

    frameWidth = (frustum[1] - frustum[0]).magnitude()
    frameHeight = (frustum[3] - frustum[0]).magnitude()
  }
}
