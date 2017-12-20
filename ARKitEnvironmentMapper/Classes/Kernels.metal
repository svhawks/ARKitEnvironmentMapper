#include <metal_stdlib>
using namespace metal;

struct FrameInfo {
  float4 p0;
  float4 p1;
  float4 p2;
  float4 p3;

  float4 forward;

  float envMapWidth;
  float envMapHeight;
  float frameWidth;
  float frameHeight;
};

// This kernel method shoots a ray towards the directions inside `coordinateConversionTexture`.
// If the point where the ray intersects the unit sphere falls inside the frame rectangle,
// we update the environment map pixel correspoding to the direction vector.
kernel void updateEnvironmentMap(texture2d<float, access::read> currentFrameTexture [[texture(0)]],
                                 texture2d<float, access::read> coordinateConversionTexture [[texture(1)]],
                                 texture2d<float, access::write> environmentMap [[texture(2)]],
                                 device FrameInfo &frame [[buffer(0)]],
                                 uint2 gid [[thread_position_in_grid]])
{
  // get .zyx because of the BGRA -> RGBA conversion from MTLTexture to texture2d
  const float3 rd = (coordinateConversionTexture.read(gid).zyx * 2.0f) - 1.0f;
  const float3 n = frame.forward.xyz;
  const float D = -1 * (dot(n, frame.p3.xyz));

  const float t = -D / (dot(n, rd));
  // check if ray intersects with the frame plane
  if (t > 0) {
    // get the intersection point
    const float3 projection = t * rd;

    const float3 p = projection - frame.p3.xyz;

    const float3 projNormalX = normalize(frame.p2.xyz - frame.p3.xyz);
    const float3 projNormalY = normalize(frame.p0.xyz - frame.p3.xyz);

    // project the intersection point to 2d where the origin is the top left corner of the frame
    float x = dot(projNormalX, p);
    float y = dot(projNormalY, p);

    // check if the intersction point lies inside the frame rect
    if (x >= 0 && x < frame.envMapWidth && y >= 0 && y < frame.envMapHeight) {
      x = x / frame.envMapWidth;
      y = y / frame.envMapHeight;
      uint textureCoordX = x * frame.frameWidth;
      uint textureCoordY = y * frame.frameHeight;

      uint2 coordinates = {textureCoordX, textureCoordY};
      float4 pixel = currentFrameTexture.read(coordinates);

      environmentMap.write(pixel, gid);
    }
  }
}
