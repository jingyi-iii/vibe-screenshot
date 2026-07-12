import QtQuick
import QtQuick.Controls.Basic

Window {
    id: pw
    flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint | Qt.Tool
    color: "transparent"; title: "Preview"

    property string imagePath: ""
    property real regionX: -1; property real regionY: -1
    property real mxW: 320; property real mxH: 240
    property real g: 16
    property real iw: img.implicitWidth; property real ih: img.implicitHeight
    property real rt: iw>0&&ih>0?iw/ih:1.6
    property real dw: Math.min(iw,mxW); property real dh: dw/rt
    property real cw: img.status===Image.Ready?dw+8:170
    property real ch: img.status===Image.Ready?dh+8:120

    width: Math.max(120,cw+g*2); height: Math.max(100,ch+g*2)
    Component.onCompleted: {
        if (regionX >= 0 && regionY >= 0) {
            // Region capture — place preview near the captured area
            x = Math.max(0, Math.min(regionX + 40, Screen.width - width))
            y = Math.max(0, Math.min(regionY + 40, Screen.height - height))
        } else {
            // Full screen — center with slight random offset
            x = Math.max(0,(Screen.width-width)/2+Math.random()*60-30)
            y = Math.max(0,(Screen.height-height)/2+Math.random()*60-30)
        }
    }

    // Cursor poll hover — instant show/hide, no fade
    property bool h: false
    Timer { id: hp; interval:100; running:true; repeat:true
        onTriggered:{var c=screenshotManager.cursorGlobalPos();h=c.x>=pw.x&&c.x<pw.x+pw.width&&c.y>=pw.y&&c.y<pw.y+pw.height} }

    // Material elevation shadow (dp=2)
    Rectangle { x:g-1; y:g-1; width:cw+2; height:ch+2; radius:7; z:-1; color:"transparent"; border.color:"#10000000"; border.width:3 }
    Rectangle { x:g-3; y:g-3; width:cw+6; height:ch+6; radius:9; z:-2; color:"transparent"; border.color:"#08000000"; border.width:4 }
    Rectangle { x:g-6; y:g-6; width:cw+12; height:ch+12; radius:12; z:-3; color:"transparent"; border.color:"#04000000"; border.width:5 }

    // Card
    Rectangle { id:card; x:g; y:g; width:cw; height:ch; color:"#1E1E1E"; radius:6; border.color:"#333333"; border.width:1
        Image { id:img; anchors.centerIn:parent; width:dw; height:dh; fillMode:Image.PreserveAspectFit
            source:imagePath?"file:///"+imagePath.replace(/\\/g,"/"):""; sourceSize.width:mxW; sourceSize.height:mxH
            smooth:true; cache:false; asynchronous:false

            // Drag-to-copy (Ctrl+drag): provides data for cross-app drop
            Drag.active: ctrlDrag
            Drag.dragType: Drag.Automatic
            Drag.mimeData: imagePath ? { "text/uri-list": ["file:///" + imagePath.replace(/\\/g, "/")] } : {}
            Drag.supportedActions: Qt.CopyAction
        }
        Rectangle { anchors.fill:parent; color:"#1E1E1E"; visible:img.status!==Image.Ready
            Text { anchors.centerIn:parent; text:"..."; color:"#5A5444"; font.pixelSize:14; font.family:"Segoe UI" } }

        // Overlay
        Rectangle { anchors.fill:parent; radius:6; color:"#cc1E1E1E"; opacity:h?1:0

            Row { anchors.centerIn:parent; spacing:24
                // Copy
                Rectangle { id:copyBtn; width:48; height:48; radius:16
                    color: b1.containsMouse ? (b1.pressed ? "#3D3020" : "#2A2418") : (copyBtn.cpDone ? "#1A2E1A" : "#252525")
                    scale: b1.pressed ? 0.88 : 1.0
                    Behavior on scale { NumberAnimation{duration:100; easing.type:Easing.OutBack} }
                    Behavior on color { ColorAnimation{duration:150} }
                    property bool cpDone: false
                    Rectangle { x:15; y:11; width:18; height:22; radius:3
                        color:"transparent"; border.color: copyBtn.cpDone ? "#34a853" : "#D19740"; border.width:2 }
                    Rectangle { x:10; y:14; width:18; height:22; radius:3
                        color:"#252525"; border.color: copyBtn.cpDone ? "#34a853" : "#D19740"; border.width:2 }
                    MouseArea { id:b1; anchors.fill:parent; hoverEnabled:true; cursorShape:Qt.PointingHandCursor
                        onClicked: {
                            screenshotManager.copyImageToClipboard(imagePath)
                            copyBtn.cpDone = true
                            cpTimer.restart()
                        } }
                    Timer { id:cpTimer; interval:800; onTriggered: copyBtn.cpDone = false }
                }
                // Fullscreen preview
                Rectangle { width:48; height:48; radius:16
                    color: b2.containsMouse ? (b2.pressed ? "#3D3020" : "#2A2418") : "#252525"
                    scale: b2.pressed ? 0.88 : 1.0
                    Behavior on scale { NumberAnimation{duration:100; easing.type:Easing.OutBack} }
                    Behavior on color { ColorAnimation{duration:150} }
                    // Maximize icon — four corner brackets
                    Rectangle { x:12; y:14; width:8; height:2; radius:1; color:"#8A8166" }
                    Rectangle { x:12; y:14; width:2; height:8; radius:1; color:"#8A8166" }
                    Rectangle { x:28; y:14; width:8; height:2; radius:1; color:"#8A8166" }
                    Rectangle { x:34; y:14; width:2; height:8; radius:1; color:"#8A8166" }
                    Rectangle { x:12; y:32; width:8; height:2; radius:1; color:"#8A8166" }
                    Rectangle { x:12; y:26; width:2; height:8; radius:1; color:"#8A8166" }
                    Rectangle { x:28; y:32; width:8; height:2; radius:1; color:"#8A8166" }
                    Rectangle { x:34; y:26; width:2; height:8; radius:1; color:"#8A8166" }
                    MouseArea { id:b2; anchors.fill:parent; hoverEnabled:true; cursorShape:Qt.PointingHandCursor
                        onClicked: fsView.show() } }
                // Save
                Rectangle { width:48; height:48; radius:16
                    color: b3.containsMouse ? (b3.pressed ? "#1A3A1A" : "#1A2E1A") : "#252525"
                    scale: b3.pressed ? 0.88 : 1.0
                    Behavior on scale { NumberAnimation{duration:100; easing.type:Easing.OutBack} }
                    Behavior on color { ColorAnimation{duration:150} }
                    Rectangle { x:11; y:30; width:26; height:3; radius:1; color:"#34a853" }
                    Rectangle { x:22; y:15; width:4; height:16; radius:1; color:"#34a853" }
                    Rectangle { x:16; y:22; width:8; height:3; radius:1; color:"#34a853"; rotation:40 }
                    Rectangle { x:24; y:22; width:8; height:3; radius:1; color:"#34a853"; rotation:-40 }
                    MouseArea { id:b3; anchors.fill:parent; hoverEnabled:true; cursorShape:Qt.PointingHandCursor
                        onClicked:screenshotManager.saveImageToFile(imagePath) } }
                // Close
                Rectangle { width:48; height:48; radius:16
                    color: b4.containsMouse ? (b4.pressed ? "#3D1818" : "#2E1818") : "#252525"
                    scale: b4.pressed ? 0.88 : 1.0
                    Behavior on scale { NumberAnimation{duration:100; easing.type:Easing.OutBack} }
                    Behavior on color { ColorAnimation{duration:150} }
                    Rectangle { anchors.centerIn:parent; width:3.5; height:22; radius:2; color:"#ea4335"; rotation:45 }
                    Rectangle { anchors.centerIn:parent; width:3.5; height:22; radius:2; color:"#ea4335"; rotation:-45 }
                    MouseArea { id:b4; anchors.fill:parent; hoverEnabled:true; cursorShape:Qt.PointingHandCursor
                        onClicked:{screenshotManager.deletePreview(imagePath);pw.destroy()} } } } } }

    // Drag: normal = move window, Ctrl+drag = copy to other apps
    property bool ctrlDrag: false
    MouseArea { anchors.fill:card; z:-1; acceptedButtons:Qt.LeftButton
        cursorShape: ctrlDrag ? Qt.DragCopyCursor : Qt.SizeAllCursor
        property real gx: 0; property real gy: 0; property real lx: 0; property real ly: 0
        onPressed: function(m) {
            var cp = screenshotManager.cursorGlobalPos()
            gx = cp.x - pw.x; gy = cp.y - pw.y
            lx = m.x; ly = m.y
            ctrlDrag = false
        }
        onPositionChanged: function(m) {
            if (pressed) {
                if (m.modifiers & Qt.ControlModifier) {
                    if (!ctrlDrag && (Math.abs(m.x-lx) > 5 || Math.abs(m.y-ly) > 5))
                        ctrlDrag = true
                } else {
                    var cp = screenshotManager.cursorGlobalPos()
                    pw.x = cp.x - gx; pw.y = cp.y - gy
                }
            }
        }
    }

    Shortcut { sequence:"Esc"; onActivated:{screenshotManager.deletePreview(imagePath);pw.destroy()} }

    // ═══ Fullscreen viewer ═══
    Window {
        id: fsView
        visible: false; color: "#151515"; title: ""
        flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint

        Rectangle { anchors.fill:parent; color:"#151515" }

        Image {
            anchors.centerIn: parent
            width: Math.min(implicitWidth, parent.width - 100)
            height: Math.min(implicitHeight, parent.height - 150)
            fillMode: Image.PreserveAspectFit
            source: img.source; smooth: true; cache: false
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom; anchors.bottomMargin: 40
            text: "Click anywhere or press Esc to close"
            color: "#5A5444"; font.pixelSize: 13
        }

        MouseArea { anchors.fill:parent; onClicked:fsView.close() }
        Shortcut { sequence:"Esc"; onActivated:fsView.close() }

        function show() { showFullScreen() }
    }
}
