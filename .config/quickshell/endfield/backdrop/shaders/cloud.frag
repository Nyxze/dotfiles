#version 440

layout(location = 0) in vec3 vPoint;
layout(location = 1) in vec2 vCorner;
layout(location = 2) in float vFade;

layout(location = 0) out vec4 fragColor;

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

void main() {
    // A sprite's four corners all quote the same point, so the position is
    // exactly constant across it and its derivative is exactly zero. On a
    // triangle bridging two sprites it is not. That is the whole test, and it
    // is the reason the position is carried here at all.
    if (fwidth(vPoint.x) + fwidth(vPoint.y) + fwidth(vPoint.z) > 1e-5)
        discard;

    // Well under one, so overlapping points build up tone instead of clipping
    // to white the moment two land on the same pixel. Density carries the form
    // here; a bright dot throws that away.
    float falloff = 1.0 - smoothstep(0.25, 1.0, length(vCorner));
    fragColor = vec4(lineColor.rgb, 1.0) * (falloff * vFade * qt_Opacity);
}
