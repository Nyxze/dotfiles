#version 440

// The planet is intersected per pixel, not tessellated, so this stage has
// nothing to place: it hands the fragment stage a screen coordinate and gets
// out of the way. It still exists because Qt's built-in vertex shader declares
// its own uniform block, and a block that disagrees with the fragment stage's
// about where `qt_Opacity` sits reads garbage out of it.

layout(location = 0) in vec4 qt_Vertex;
layout(location = 1) in vec2 qt_MultiTexCoord0;

layout(location = 0) out vec2 vCoord;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    vec4 lineColor;
    vec4 impactA;
    vec4 impactB;
    vec4 impactC;
    vec2 viewport;
    float qt_Opacity;
    float time;
    float radius;
    float camDist;
    float disc;
    float tilt;
    float spin;
};

void main() {
    vCoord = qt_MultiTexCoord0;
    gl_Position = qt_Matrix * qt_Vertex;
}
