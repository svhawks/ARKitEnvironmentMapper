Pod::Spec.new do |s|
  s.name             = 'ARKitEnvironmentMapper'
  s.version          = '0.3.0'
  s.summary          = 'Real-time environment map generator for ARKit'
  s.description      = <<-DESC
 A library that allows you to generate and update environment maps in real-time using the camera feed and ARKit's tracking capabilities.
                       DESC

  s.homepage         = 'https://github.com/svtek/ARKitEnvironmentMapper'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'halileohalilei' => 'halil@mojilala.com' }
  s.source           = { :git => 'https://github.com/svtek/ARKitEnvironmentMapper.git', :tag => s.version }
  s.social_media_url = 'https://twitter.com/halileohalilei'

  s.ios.deployment_target = '11.0'

  s.source_files = 'ARKitEnvironmentMapper/Classes/**/*'

  s.frameworks = 'Metal', 'MetalKit', 'ARKit', 'SceneKit', 'CoreGraphics', 'QuartzCore'

  s.dependency 'Vivid'
end
