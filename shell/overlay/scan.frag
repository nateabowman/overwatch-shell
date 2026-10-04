#version 440
// Faint scanlines, a slow sweep band and a vignette, drawn as translucent black/teal.
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float time;
    float lines;
};
void main() {
    vec2 uv = qt_TexCoord0;
    float line = 0.5 + 0.5 * sin(uv.y * lines * 3.14159);
    float dark = line * 0.055;
    vec2 v = uv - 0.5;
    dark += dot(v, v) * 0.22;
    float sweep = smoothstep(0.035, 0.0, abs(uv.y - fract(time * 0.045))) * 0.022;
    vec3 tint = vec3(0.37, 0.84, 0.91) * sweep;
    fragColor = vec4(tint, dark + sweep) * qt_Opacity;
}
