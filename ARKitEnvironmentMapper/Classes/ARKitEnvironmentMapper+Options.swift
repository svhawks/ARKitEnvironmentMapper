
public extension ARKitEnvironmentMapper {
  public struct Options {
    public var updatesPerSecond: Int
    public var experimentalExposureCorrectionEnabled: Bool

    public static var `default`: Options {
      return Options(updatesPerSecond: 10,
                     experimentalExposureCorrectionEnabled: false)
    }
  }
}
