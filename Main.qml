import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic

ApplicationWindow {
    id: w
    width: 300; height: 260
    minimumWidth: 300; minimumHeight: 260
    maximumWidth: 300; maximumHeight: 260
    visible: true; title: "Screenshot"
    flags: Qt.Window | Qt.FramelessWindowHint
    color: "transparent"

    Shortcut { sequence: "Ctrl+Shift+A"; onActivated: screenshotManager.startRegionCapture() }
    Shortcut { sequence: "Ctrl+Shift+S"; onActivated: screenshotManager.captureFullScreen() }

    Connections {
        target: screenshotManager
        function onRegionCaptureStarted()    { w.opacity = 0; rs.open() }
        function onRegionCaptureCancelled()   { w.opacity = 1 }
        function onRegionCaptured(p, rx, ry)  { w.opacity = 1; mk(p, rx, ry) }
        function onFullScreenCaptureStarting() {}
        function onFullScreenCaptured(p)      { w.opacity = 1; mk(p) }
    }
    RegionSelector { id: rs; visible: false }

    property var pws: []
    Component { id: pc; PreviewWindow {} }
    function mk(p, rx, ry) {
        if(pc.status===Component.Ready){var pw=pc.createObject(null,{"imagePath":p,"regionX":rx||-1,"regionY":ry||-1});if(pw){pw.Component.onDestruction.connect(function(){var i=pws.indexOf(pw);if(i>=0)pws.splice(i,1)});pws.push(pw);pw.show()}}
        else if(pc.status===Component.Error)console.log("err:",pc.errorString())
        else pc.statusChanged.connect(function(){if(pc.status===Component.Ready)mk(p, rx, ry)})
    }

    MouseArea { anchors.fill:parent; acceptedButtons:Qt.LeftButton
        property real gx: 0; property real gy: 0
        onPressed:function(m){var cp=screenshotManager.cursorGlobalPos();gx=cp.x-w.x;gy=cp.y-w.y}
        onPositionChanged:function(m){if(pressed){var cp=screenshotManager.cursorGlobalPos();w.x=cp.x-gx;w.y=cp.y-gy}} }

    Rectangle {
        anchors.fill: parent; radius: 12
        color: "#1E1E1E"
        border.color: "#333333"; border.width: 1

        // Material elevation shadow (dp=2) — subtle dark glow
        Rectangle { anchors.fill:parent; anchors.margins:-1; radius:13; z:-1
            color:"transparent"; border.color:"#0d000000"; border.width:3 }
        Rectangle { anchors.fill:parent; anchors.margins:-3; radius:15; z:-2
            color:"transparent"; border.color:"#06000000"; border.width:4 }
        Rectangle { anchors.fill:parent; anchors.margins:-6; radius:18; z:-3
            color:"transparent"; border.color:"#03000000"; border.width:5 }

        // Minimize button
        Rectangle {
            x: parent.width - 36; y: 14
            width: 28; height: 28; radius: 14
            color: mb.containsMouse ? "#333333" : "transparent"
            Behavior on color { ColorAnimation { duration: 120 } }
            Text {
                anchors.centerIn: parent
                text: "\u2212"; color: "#8A8166"; font.pixelSize: 16; font.weight: Font.Bold
            }
            MouseArea {
                id: mb; anchors.fill: parent; hoverEnabled: true
                cursorShape: Qt.PointingHandCursor; onClicked: { screenshotManager.cancelRegionCapture(); rs.dismiss(); w.visible = false }
            }
        }

        ColumnLayout {
            anchors.centerIn: parent; spacing: 18

            Text {
                Layout.alignment: Qt.AlignLeft
                text: "Screenshot"
                color: "#F3E0A5"; font.pixelSize: 18; font.weight: Font.Bold
            }

            // Shortcut row — Region
            RowLayout {
                Layout.alignment: Qt.AlignLeft; spacing: 10
                Rectangle { width: 32; height: 24; radius: 5; color: "#2A2A2A"; border.color: "#444444"; border.width: 1
                    Text { anchors.centerIn:parent; text:"Ctrl"; color:"#8A8166"; font.pixelSize:10; font.weight:Font.DemiBold } }
                Text { text:"+"; color:"#5A5444"; font.pixelSize:12 }
                Rectangle { width: 32; height: 24; radius: 5; color: "#2A2A2A"; border.color: "#444444"; border.width: 1
                    Text { anchors.centerIn:parent; text:"Shift"; color:"#8A8166"; font.pixelSize:10; font.weight:Font.DemiBold } }
                Text { text:"+"; color:"#5A5444"; font.pixelSize:12 }
                Rectangle { width: 24; height: 24; radius: 5; color: "#2A2A2A"; border.color: "#444444"; border.width: 1
                    Text { anchors.centerIn:parent; text:"A"; color:"#8A8166"; font.pixelSize:12; font.weight:Font.DemiBold } }
                Text { text:"\u2014"; color:"#333333"; font.pixelSize:12 }
                Text { text:"Region"; color:"#8A8166"; font.pixelSize:13 }
            }

            // Shortcut row — Fullscreen
            RowLayout {
                Layout.alignment: Qt.AlignLeft; spacing: 10
                Rectangle { width: 32; height: 24; radius: 5; color: "#2A2A2A"; border.color: "#444444"; border.width: 1
                    Text { anchors.centerIn:parent; text:"Ctrl"; color:"#8A8166"; font.pixelSize:10; font.weight:Font.DemiBold } }
                Text { text:"+"; color:"#5A5444"; font.pixelSize:12 }
                Rectangle { width: 32; height: 24; radius: 5; color: "#2A2A2A"; border.color: "#444444"; border.width: 1
                    Text { anchors.centerIn:parent; text:"Shift"; color:"#8A8166"; font.pixelSize:10; font.weight:Font.DemiBold } }
                Text { text:"+"; color:"#5A5444"; font.pixelSize:12 }
                Rectangle { width: 24; height: 24; radius: 5; color: "#2A2A2A"; border.color: "#444444"; border.width: 1
                    Text { anchors.centerIn:parent; text:"S"; color:"#8A8166"; font.pixelSize:12; font.weight:Font.DemiBold } }
                Text { text:"\u2014"; color:"#333333"; font.pixelSize:12 }
                Text { text:"Full Screen"; color:"#8A8166"; font.pixelSize:13 }
            }

            // Divider
            Rectangle { Layout.fillWidth:true; height:1; color:"#2E2E2E" }

            // Drag hint
            RowLayout {
                Layout.alignment: Qt.AlignLeft; spacing: 10
                Rectangle { width: 32; height: 24; radius: 5; color: "#2A2A2A"; border.color: "#444444"; border.width: 1
                    Text { anchors.centerIn:parent; text:"Ctrl"; color:"#8A8166"; font.pixelSize:10; font.weight:Font.DemiBold } }
                Text { text:"+ Drag"; color:"#5A5444"; font.pixelSize:12 }
                Text { text:"\u2014"; color:"#333333"; font.pixelSize:12 }
                Text { text:"Drag the pictures to paste"; color:"#8A8166"; font.pixelSize:13 }
            }

        }
    }

    Shortcut { sequence: "Esc"; onActivated: { for(var i=0;i<pws.length;i++){if(pws[i])pws[i].destroy()};pws=[];Qt.quit() } }
}
