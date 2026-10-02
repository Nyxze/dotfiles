#version 440

// One baked point cloud, placed in the scene and projected through the planet's
// camera. The mesh behind this is a grid of 2·side vertices per axis, and each
// 2×2 block of them is a single point's sprite: Qt Quick's scene graph has no
// point primitive, and a grid of quads is the only way to get one out of a
// ShaderEffect.
//
// The grid's own triangles still bridge one block to the next. Those cannot be
// removed here — the topology is not ours — so the point's position travels to
// the fragment stage, where a bridge gives itself away by changing across the
// primitive.

layout(location = 0) in vec4 qt_Vertex;
layout(location = 1) in vec2 qt_MultiTexCoord0;

layout(location = 0) out vec3 vPoint;
layout(location = 1) out vec2 vCorner;
layout(location = 2) out float vFade;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    vec4 lineColor;
    vec3 origin;
    vec3 up;
    vec2 viewport;
    float qt_Opacity;
    float time;
    float radius;
    float camDist;
    float disc;
    float side;
    float size;
    float yaw;
    float dotSize;
    float ink;
};

layout(binding = 1) uniform sampler2D cloudHi;
layout(binding = 2) uniform sampler2D cloudLo;

// How much of the far side still shows. At zero the cloud reads as a solid
// shell and stops looking like a cloud.
const float BACK = 0.35;

void main() {
    float span = side * 2.0 - 1.0;
    vec2 cell = floor(qt_MultiTexCoord0 * span + 0.5);
    vec2 block = floor(cell * 0.5);
    vec2 corner = cell - block * 2.0;

    vec2 texel = (block + 0.5) / side;
    vec4 hi = texture(cloudHi, texel);
    vec4 lo = texture(cloudLo, texel);

    // Two bytes per axis, reassembled. One byte leaves a lattice coarse enough
    // to watch the cloud snap between steps as it turns.
    vec3 point = ((hi.rgb * 255.0 * 256.0 + lo.rgb * 255.0) / 65535.0) * 2.0 - 1.0;

    // The grid is square and the cloud is not, so its tail is padding. Alpha
    // says which is which; a padded sprite collapses to a point and rasterises
    // nothing, rather than piling dots up at the model's centre.
    float real = step(0.5, hi.a);

    // A basis with the model's own Y laid along `up`, so a pod can ride its
    // trajectory blunt end first without the caller having to work out a pair
    // of Euler angles for a direction it already has as a vector.
    vec3 uy = normalize(up);
    vec3 ref = abs(uy.y) > 0.9 ? vec3(0.0, 0.0, 1.0) : vec3(0.0, 1.0, 0.0);
    vec3 ux = normalize(cross(ref, uy));
    vec3 uz = cross(uy, ux);

    float cy = cos(yaw);
    float sy = sin(yaw);
    vec3 spun = vec3(point.x * cy - point.z * sy, point.y, point.x * sy + point.z * cy);

    vec3 world = origin + size * (ux * spun.x + uy * spun.y + uz * spun.z);

    vec3 eye = vec3(0.0, 0.0, camDist);
    vec3 rel = world - eye;
    float depth = max(-rel.z, 0.01);

    // The planet's own projection, restated forwards. Anything that draws
    // alongside it has to solve the same scale from the same disc, or the two
    // drift apart the moment either is retuned.
    float k = (radius / sqrt(camDist * camDist - radius * radius)) / disc;
    vec2 proj = rel.xy / depth / k;
    vec2 screen = vec2(viewport.x * 0.5 + proj.x * viewport.y * 0.5,
                       viewport.y * 0.5 - proj.y * viewport.y * 0.5);

    // Hidden when the planet is between this point and the eye. Tested per
    // sprite rather than per pixel: a point is wholly in front or wholly
    // behind, and this is the cue that puts the cloud in space around the
    // planet instead of on a layer above it.
    vec3 dir = rel / max(length(rel), 1e-6);
    float miss = length(cross(dir, eye));
    float front = -dot(eye, dir) - sqrt(max(radius * radius - miss * miss, 0.0));
    float hidden = step(miss, radius) * step(0.0, front) * step(front, length(rel));

    real *= 1.0 - hidden;
    screen += (corner * 2.0 - 1.0) * dotSize * 0.5 * real;

    vPoint = point;
    vCorner = corner * 2.0 - 1.0;
    vFade = real * ink * mix(BACK, 1.0, clamp((camDist + 1.0 - depth) * 0.5, 0.0, 1.0));

    gl_Position = qt_Matrix * vec4(screen, 0.0, 1.0);
}
