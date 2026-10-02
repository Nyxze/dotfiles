import ".."
import "../components"
import QtQuick
import QtQuick.Layouts

// Month grid, Monday first. Navigating never moves `today`, so the current day
// stays highlighted only when its own month is on screen.
ColumnLayout {
    id: cal

    readonly property var locale: Qt.locale("fr_FR")
    readonly property date today: new Date()

    property int viewYear: today.getFullYear()
    property int viewMonth: today.getMonth()

    readonly property date viewDate: new Date(viewYear, viewMonth, 1)
    // Date.getDay() is Sunday-based; shift so Monday is column 0.
    readonly property int leadingBlanks: (viewDate.getDay() + 6) % 7
    readonly property int daysInMonth: new Date(viewYear, viewMonth + 1, 0).getDate()

    function shiftMonth(delta) {
        const d = new Date(viewYear, viewMonth + delta, 1);
        viewYear = d.getFullYear();
        viewMonth = d.getMonth();
    }

    function resetToToday() {
        viewYear = today.getFullYear();
        viewMonth = today.getMonth();
    }

    spacing: Theme.space(3)

    RowLayout {
        Layout.fillWidth: true
        spacing: Theme.space(2)

        Text {
            Layout.fillWidth: true
            text: cal.viewDate.toLocaleString(cal.locale, "MMMM yyyy")
            color: Theme.textPrimary
            font: Theme.h2
        }

        IconButton {
            glyph: "‹"
            onActivated: cal.shiftMonth(-1)
        }

        IconButton {
            glyph: "󰃭"
            onActivated: cal.resetToToday()
        }

        IconButton {
            glyph: "›"
            onActivated: cal.shiftMonth(1)
        }
    }

    GridLayout {
        Layout.fillWidth: true
        columns: 7
        columnSpacing: Theme.space(1)
        rowSpacing: Theme.space(1)

        Repeater {
            model: 7

            Text {
                required property int index

                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: cal.locale.standaloneDayName((index + 1) % 7, Locale.ShortFormat)
                color: Theme.textMuted
                font: Theme.label
            }
        }

        Repeater {
            model: 42

            Item {
                required property int index

                readonly property int day: index - cal.leadingBlanks + 1
                readonly property bool inMonth: day >= 1 && day <= cal.daysInMonth
                readonly property bool isToday: inMonth
                    && day === cal.today.getDate()
                    && cal.viewMonth === cal.today.getMonth()
                    && cal.viewYear === cal.today.getFullYear()

                Layout.fillWidth: true
                implicitHeight: Theme.space(9)

                Rectangle {
                    anchors.centerIn: parent
                    width: Theme.space(7)
                    height: Theme.space(7)
                    color: parent.isToday ? Theme.accent : "transparent"
                }

                Text {
                    anchors.centerIn: parent
                    visible: parent.inMonth
                    text: parent.day
                    color: parent.isToday ? Theme.onAccent : Theme.textSecondary
                    font: parent.isToday ? Theme.h3 : Theme.body
                }
            }
        }
    }
}
