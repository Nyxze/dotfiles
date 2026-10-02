import ".."
import QtQuick

// The sky the orbit scene sits in. Fixed points, thinned out of the planet's
// disc so the limb reads as the edge of a body rather than as a wireframe with
// stars showing through it.
//
// Rectangles rather than a shader because there is nothing here a shader would
// buy: a few hundred single-pixel points never move, and the scene graph draws
// them in one batch.
Item {
    id: root

    // How many points are cast over the frame. The ones the planet covers are
    // dropped rather than moved aside, so the sky carries somewhat fewer than
    // this and its density stays even across the frame.
    //
    // Density is what makes a sky read as one, not brightness: a sparse field
    // bright enough to be counted reads as dirt on the screen.
    property int count: 1000

    // The planet's limb, as a fraction of half the frame height — the same
    // `disc` the scene hands its shaders. Zero draws the field whole.
    property real disc: 0

    property color color: Theme.textPrimary

    // The brightest star; every other one is a fraction of it. The band sits
    // below the globe's rim on purpose — this is a ground, and a sky that
    // competes with the plate in front of it is drawn too bright.
    property real ink: 0.34

    // Seeded rather than random. The greeter and the lock screen are one
    // moment of the session seen from either side of it, so they have to come
    // up under the same stars, and a reload must not reshuffle them.
    property int seed: 7

    function stream(from) {
        // Lehmer. The multiplier is small enough that the product stays under
        // 2^53 — a textbook LCG constant overflows the double and collapses
        // the sequence into a short cycle.
        let state = from % 2147483646 + 1;
        return () => (state = state * 16807 % 2147483647) / 2147483647;
    }

    readonly property var field: {
        if (width <= 0 || height <= 0)
            return [];

        const next = stream(root.seed);
        const limb = root.disc * height / 2;
        const out = [];

        for (let i = 0; i < root.count; ++i) {
            // Rounded: a star is one pixel, and a fractional position smears it
            // over two at a fraction of the brightness it was given.
            const x = Math.round(next() * (width - 2));
            const y = Math.round(next() * (height - 2));
            const near = next() < 0.07;
            const level = next();
            const blinks = next() < 0.12;
            const period = 1200 + next() * 1400;
            const rest = next() * 9000;

            const dx = x - width / 2;
            const dy = y - height / 2;
            // Clear of the rim rather than stopping on it: the rim is a drawn
            // line, and a star sitting in it reads as a break in the limb.
            if (Math.sqrt(dx * dx + dy * dy) < limb + 2)
                continue;

            out.push({
                x: x,
                y: y,
                size: near ? 2 : 1,
                ink: root.ink * (near ? 0.70 + level * 0.30 : 0.28 + level * 0.40),
                period: blinks ? period : 0,
                rest: rest
            });
        }

        return out;
    }

    Repeater {
        model: root.field

        Rectangle {
            id: star

            required property var modelData

            x: star.modelData.x
            y: star.modelData.y
            width: star.modelData.size
            height: star.modelData.size
            // The alpha rides in the colour rather than on `opacity`, which
            // leaves every star the same material and the whole sky one batch.
            // `opacity` is then free for the blink, and the two multiply.
            color: Qt.rgba(root.color.r, root.color.g, root.color.b, star.modelData.ink)
            antialiasing: false

            // A few of them, never in step. A whole sky breathing at one rate
            // reads as the screen flickering rather than as distance, which is
            // what the pause between blinks is for as much as the phase it
            // gives each star.
            SequentialAnimation {
                running: star.modelData.period > 0
                loops: Animation.Infinite

                PauseAnimation {
                    duration: star.modelData.rest
                }

                NumberAnimation {
                    target: star
                    property: "opacity"
                    to: 0.3
                    duration: star.modelData.period
                    easing.type: Easing.InOutSine
                }

                NumberAnimation {
                    target: star
                    property: "opacity"
                    to: 1
                    duration: star.modelData.period
                    easing.type: Easing.InOutSine
                }
            }
        }
    }
}
