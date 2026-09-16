#version 440

// The planet, intersected per pixel rather than tessellated. Silhouette,
// contours and graticule all fall out of the same ray hit, so the limb stays
// exact at any resolution and nothing has to be culled — the near intersection
// is the only surface a pixel can ever see.
//
// The camera lives in uniforms rather than in constants here because it is not
// this shader's alone: everything drawn around the planet has to project and
// occlude against the same one, and a second copy of these numbers is a second
// place for them to drift.

layout(location = 0) in vec2 vCoord;

layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    vec4 lineColor;
    // Impact sites: a unit vector in the planet's own frame, and the time the
    // ripple started. A negative time means the slot is empty.
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

const float PI = 3.14159265;
const float TAU = 6.28318531;

// How much terrain the sphere carries, in noise units per radius.
const float FIELD_SCALE = 2.6;

// Contour interval, as a count over the field's range, and how often one of
// them is an index contour.
const float LEVELS = 14.0;
const float INDEX_EVERY = 5.0;

// Graticule, as whole counts so the meridians close on themselves.
const float MERIDIANS = 24.0;
const float PARALLELS = 12.0;

// How the ripple travels: radians of arc per second, and how long it lasts.
const float RIPPLE_SPEED = 0.11;
const float RIPPLE_LIFE = 5.0;

float hash(vec3 p) {
    p = fract(p * 0.3183099 + vec3(0.71, 0.113, 0.419));
    p *= 17.0;
    return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

// Noise in three dimensions, not two: a field sampled on latitude and longitude
// pinches at the poles and tears along the date line, and both show up as
// contours that converge on a defect rather than on a summit.
float valueNoise(vec3 p) {
    vec3 i = floor(p);
    vec3 f = fract(p);
    // Smoothstep, not linear: a linear blend leaves the lattice visible as a
    // crease along every cell boundary, and a contour crossing it kinks.
    f = f * f * (3.0 - 2.0 * f);

    return mix(mix(mix(hash(i + vec3(0.0, 0.0, 0.0)), hash(i + vec3(1.0, 0.0, 0.0)), f.x),
                   mix(hash(i + vec3(0.0, 1.0, 0.0)), hash(i + vec3(1.0, 1.0, 0.0)), f.x), f.y),
               mix(mix(hash(i + vec3(0.0, 0.0, 1.0)), hash(i + vec3(1.0, 0.0, 1.0)), f.x),
                   mix(hash(i + vec3(0.0, 1.0, 1.0)), hash(i + vec3(1.0, 1.0, 1.0)), f.x), f.y), f.z);
}

float terrain(vec3 p) {
    float h = 0.0;
    float weight = 0.0;
    float amp = 1.0;
    float lattice = 1.0;

    for (int i = 0; i < 5; ++i) {
        h += valueNoise(p * lattice) * amp;
        weight += amp;
        lattice *= 2.0;
        amp *= 0.5;
    }

    h /= weight;
    // Folding about the midpoint turns rounded hills into crests, which bunches
    // the contours into ridgelines instead of spacing them evenly.
    return 1.0 - abs(h - 0.5) * 2.0;
}

// A line wherever v crosses a whole number, one pixel wide given how fast v
// runs across the screen. It thins out on its own where the curvature crowds
// the lines past a pixel apart, rather than aliasing into moire.
float ruled(float v, float w) {
    return 1.0 - clamp(abs(fract(v - 0.5) - 0.5) / max(w, 1e-6), 0.0, 1.0);
}

float edgeLine(float d, float w) {
    return 1.0 - clamp(abs(d) / max(w, 1e-6), 0.0, 1.0);
}

// World space into the planet's own frame, which is where the terrain and the
// impact sites live: turning the field under a fixed sphere is what makes the
// planet rotate without the silhouette moving with it.
vec3 toPlanet(vec3 p) {
    float ct = cos(tilt);
    float st = sin(tilt);
    vec3 q = vec3(p.x, p.y * ct + p.z * st, -p.y * st + p.z * ct);

    float turn = mod(time * spin, TAU);
    float cs = cos(turn);
    float ss = sin(turn);
    return vec3(q.x * cs - q.z * ss, q.y, q.x * ss + q.z * cs);
}

// One expanding ring, measured along the surface rather than across the chord,
// so it stays a circle on the sphere instead of flattening as it grows.
float ripple(vec3 surface, vec4 impact) {
    if (impact.w < 0.0)
        return 0.0;

    float age = time - impact.w;
    if (age < 0.0 || age > RIPPLE_LIFE)
        return 0.0;

    float arc = acos(clamp(dot(surface, impact.xyz), -1.0, 1.0));
    float ring = edgeLine(arc - age * RIPPLE_SPEED, fwidth(arc) + 0.002);

    // Fades as it goes, and the leading edge is what carries it: a ring that
    // dims uniformly reads as the whole surface flickering.
    return ring * (1.0 - age / RIPPLE_LIFE);
}

void main() {
    // Half-height units, so the framing is independent of the aspect ratio.
    vec2 screen = vec2((vCoord.x - 0.5) * viewport.x / viewport.y,
                       0.5 - vCoord.y) * 2.0;

    // The scale comes out of the wanted disc size: the limb is where the ray
    // grazes the sphere, so fixing its screen radius fixes the projection.
    float grazing = radius / sqrt(camDist * camDist - radius * radius);
    vec3 eye = vec3(0.0, 0.0, camDist);
    vec3 ray = normalize(vec3(screen * grazing / disc, -1.0));

    // How close the ray passes to the centre. The silhouette depends on nothing
    // else, so the rim can be drawn before deciding whether there is a surface.
    float miss = length(cross(ray, eye));
    float rim = edgeLine(miss - radius, fwidth(miss));
    float inside = clamp((radius - miss) / max(fwidth(miss), 1e-6) + 0.5, 0.0, 1.0);

    // Outside the disc this lands on the point of closest approach instead of
    // on the sphere. It stays finite, which is all that matters: `inside` masks
    // everything derived from it.
    float depth = -dot(eye, ray) - sqrt(max(radius * radius - miss * miss, 0.0));
    vec3 hit = eye + ray * depth;
    vec3 local = toPlanet(hit);
    vec3 surface = normalize(local);

    float level = terrain(local * FIELD_SCALE) * LEVELS;
    float contour = ruled(level, fwidth(level));
    float index = ruled(level / INDEX_EVERY, fwidth(level) / INDEX_EVERY);

    // The graticule's screen-space rates are worked out by hand rather than
    // taken from fwidth. Longitude wraps at the date line, and fwidth reads that
    // wrap as an infinite rate, which erases the meridian sitting on the seam.
    vec3 dx = dFdx(local);
    vec3 dy = dFdy(local);

    float r2 = max(dot(local.xz, local.xz), 1e-6);
    float lon = atan(local.z, local.x) / TAU * MERIDIANS;
    float lonW = (abs(local.x * dx.z - local.z * dx.x)
                + abs(local.x * dy.z - local.z * dy.x)) / r2 / TAU * MERIDIANS;

    float sinLat = clamp(local.y / radius, -1.0, 1.0);
    float slope = inversesqrt(max(1.0 - sinLat * sinLat, 1e-6)) / radius;
    float lat = asin(sinLat) / PI * PARALLELS;
    float latW = (abs(dx.y) + abs(dy.y)) * slope / PI * PARALLELS;

    float grid = max(ruled(lon, lonW), ruled(lat, latW));

    // The surface turning away from the camera. The contours thin out there on
    // their own, so this is what keeps the limb from reading as a bald ring.
    float limb = pow(1.0 - max(dot(hit / radius, -ray), 0.0), 3.0);

    float wave = max(max(ripple(surface, impactA), ripple(surface, impactB)),
                     ripple(surface, impactC));

    // This is a ground. Drawn at the brightness a map wants, it becomes the
    // subject and the login plate becomes an obstruction laid over it.
    float ink = (contour * 0.15 + index * 0.17 + grid * 0.06 + limb * 0.11
               + wave * 0.55) * inside
              + rim * 0.30;
    fragColor = vec4(lineColor.rgb, 1.0) * (ink * qt_Opacity);
}
