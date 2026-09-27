import ".."
import QtQuick

// The orbit scene: a planet, a station parked above it, and the factories it
// drops onto the surface.
//
// This is the one place that knows the camera and the planet's frame. The globe
// and every cloud around it read those from here rather than carrying their
// own, because an occlusion test is a comparison between two projections and
// two copies of the numbers is how they stop agreeing.
Item {
    id: root

    property url models
    property url fallback

    // The planet's frame. `spin` is radians per second — a full turn in about
    // three minutes: visible if you watch it, invisible while you are typing a
    // password.
    readonly property real radius: 1
    readonly property real camDist: 3.6
    readonly property real disc: 0.78
    readonly property real tilt: 0.38
    readonly property real spin: 0.035

    // Where the station sits, in planet radii. Parked, not orbiting: the
    // Dijiang is geostationary, and a viewer reads "does not move relative to
    // the planet" as exactly that. A craft tracking across the frame would
    // describe a low orbit, and would pull the eye off the password field.
    // Held clear of the disc, high and to one side. The position is chosen in
    // projected radii rather than in depth: what matters is that the craft and
    // the limb do not touch, and moving it away from the camera alone would
    // shrink it against the planet without ever separating the two.
    readonly property vector3d station: Qt.vector3d(1.04, 0.81, 0.25)

    // Seconds between drops, and how long one takes to come down.
    property real dropInterval: 16
    property real dropDuration: 5.5

    property real time: 0

    // Planet-local to world. The shader walks this the other way to find the
    // terrain under a pixel; a drop site has to make the same trip forwards to
    // stay stuck to the ground it was chosen on.
    function toWorld(v, t) {
        const turn = (t * spin) % (Math.PI * 2);
        const cs = Math.cos(turn);
        const ss = Math.sin(turn);
        const spun = Qt.vector3d(v.x * cs + v.z * ss, v.y, -v.x * ss + v.z * cs);

        const ct = Math.cos(tilt);
        const st = Math.sin(tilt);
        return Qt.vector3d(spun.x, spun.y * ct - spun.z * st, spun.y * st + spun.z * ct);
    }

    function toLocal(v, t) {
        const ct = Math.cos(tilt);
        const st = Math.sin(tilt);
        const q = Qt.vector3d(v.x, v.y * ct + v.z * st, -v.y * st + v.z * ct);

        const turn = (t * spin) % (Math.PI * 2);
        const cs = Math.cos(turn);
        const ss = Math.sin(turn);
        return Qt.vector3d(q.x * cs - q.z * ss, q.y, q.x * ss + q.z * cs);
    }

    // A site on the half of the planet facing the camera, expressed in the
    // planet's frame at the moment the drop will land. Choosing it in world
    // space and converting is what guarantees the ripple happens where it can
    // be seen; choosing it in the planet's frame would put half of them round
    // the back.
    function pickSite(landing) {
        let dir;
        do {
            dir = Qt.vector3d(Math.random() * 2 - 1, Math.random() * 2 - 1,
                              Math.random() * 0.75 + 0.25);
        } while (dir.length() < 0.35);
        return toLocal(dir.normalized(), landing);
    }

    property var site: null
    property real launched: -1
    property int slot: 0

    readonly property real progress: launched < 0
        ? -1 : Math.min((time - launched) / dropDuration, 1)

    // Descent, as a direction and an altitude taken apart. Interpolating the
    // position straight would cut a chord through the planet on any drop that
    // travels far around it.
    function carrierAt(f) {
        const from = station.normalized();
        const to = toWorld(site, time);
        const ease = f * f * (3 - 2 * f);
        const bearing = from.times(1 - ease).plus(to.times(ease)).normalized();
        return bearing.times(station.length() * (1 - ease) + radius * ease);
    }

    readonly property vector3d carrier: site === null || progress < 0
        ? Qt.vector3d(0, 0, 0) : carrierAt(progress)

    // The tangent, taken as a difference along the path rather than derived.
    // The easing makes the speed vanish at both ends, so a derivative would be
    // zero exactly where the pod is released and where it lands; a step either
    // side still points the right way there.
    readonly property vector3d heading: {
        if (site === null || progress < 0)
            return Qt.vector3d(0, 1, 0);

        const step = 0.02;
        const run = carrierAt(Math.min(progress + step, 1))
            .minus(carrierAt(Math.max(progress - step, 0)));
        return run.length() > 1e-6 ? run.normalized() : Qt.vector3d(0, 1, 0);
    }

    // The shaders' projection, restated in JavaScript. This is the one copy
    // outside GLSL, and it exists because the trajectory is a stroked line and
    // not a cloud of sprites — there is nothing to hand a vertex stage.
    readonly property real focal: (radius / Math.sqrt(camDist * camDist - radius * radius)) / disc

    function project(w) {
        const depth = Math.max(camDist - w.z, 0.01);
        return Qt.point(width * 0.5 + w.x / depth / focal * height * 0.5,
                        height * 0.5 - w.y / depth / focal * height * 0.5);
    }

    function behind(w) {
        const eye = Qt.vector3d(0, 0, camDist);
        const rel = w.minus(eye);
        const reach = rel.length();
        const dir = rel.times(1 / reach);
        const miss = dir.crossProduct(eye).length();
        if (miss > radius)
            return false;
        const front = -eye.dotProduct(dir) - Math.sqrt(Math.max(radius * radius - miss * miss, 0));
        return front > 0 && front < reach;
    }

    // The trace stops at the first point the planet hides rather than skipping
    // it. By construction the arc never goes round the back — both ends face the
    // camera and it never dips below the surface — so this only bites if the
    // station is moved somewhere it does not belong, and truncating is a better
    // failure than a line drawn straight through the planet.
    function trace(until, steps) {
        const out = [];
        for (let i = 0; i <= steps; ++i) {
            const w = carrierAt(until * i / steps);
            if (behind(w))
                break;
            out.push(project(w));
        }
        return out;
    }

    readonly property var plotted: site === null || progress < 0 ? [] : trace(1, 48)
    readonly property var flown: site === null || progress < 0 ? [] : trace(progress, 32)

    function drop() {
        site = pickSite(time + dropDuration);
        launched = time;
        arrival.restart();
    }

    function land() {
        const impact = Qt.vector4d(site.x, site.y, site.z, time);
        if (slot === 0)
            globe.impactA = impact;
        else if (slot === 1)
            globe.impactB = impact;
        else
            globe.impactC = impact;

        slot = (slot + 1) % 3;
        launched = -1;
        site = null;
    }

    NumberAnimation on time {
        from: 0
        to: 86400
        duration: 86400000
        loops: Animation.Infinite
    }

    Timer {
        interval: root.dropInterval * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.drop()
    }

    // The landing is timed rather than watched. Reading it off `progress` meant
    // clearing `launched` from inside that property's own change handler, which
    // is a binding loop: the handler invalidates the value that invoked it.
    Timer {
        id: arrival

        interval: root.dropDuration * 1000
        repeat: false
        onTriggered: root.land()
    }

    Starfield {
        anchors.fill: parent
        disc: root.disc
    }

    Globe {
        id: globe

        anchors.fill: parent
        time: root.time
        radius: root.radius
        camDist: root.camDist
        disc: root.disc
        tilt: root.tilt
        spin: root.spin
        fallback: root.fallback
    }

    PointCloud {
        anchors.fill: parent
        source: root.models + "dijiang"
        side: 192
        origin: root.station
        size: 0.20
        up: Qt.vector3d(0, 1, 0.25)
        yaw: 0.55
        camDist: root.camDist
        disc: root.disc
        occluder: root.radius
        ink: 0.10
    }

    // The whole arc, faint and dashed, and the part already flown over it. The
    // plan is recomputed every frame on purpose: its far end is stuck to ground
    // that is turning, so a line laid down once would drift off the target.
    Trail {
        anchors.fill: parent
        points: root.plotted
        ink: 0.10
        dash: [3, 5]
    }

    Trail {
        anchors.fill: parent
        points: root.flown
        ink: 0.26
    }

    PointCloud {
        anchors.fill: parent
        visible: root.progress >= 0
        source: root.models + "pod"
        side: 32
        origin: root.carrier
        size: 0.022

        // Negated: the pod's own up is the dome, and it falls heat shield
        // first, so its axis runs back along the direction of travel.
        up: root.heading.times(-1)
        yaw: 0.4
        camDist: root.camDist
        disc: root.disc
        occluder: root.radius
        ink: 0.22
    }
}
