import QtQuick
import QtQuick.Controls.Basic

Window {
    id: rw
    flags: Qt.Tool | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
    visible: false; color: "transparent"; title: "Region"

    property point a: Qt.point(0,0); property point b: Qt.point(0,0)
    property bool d: false

    function open() {
        a=Qt.point(0,0); b=Qt.point(0,0); d=false
        cv.requestPaint()
        showFullScreen()
    }
    function dismiss() { visible=false; visibility=Window.Hidden }

    onVisibleChanged: { if (visible) cv.requestPaint() }
    function rc() { var x=Math.min(a.x,b.x),y=Math.min(a.y,b.y); return Qt.rect(x,y,Math.abs(b.x-a.x),Math.abs(b.y-a.y)) }

    Canvas { id:cv; anchors.fill:parent
        onPaint:{var c=getContext("2d");c.clearRect(0,0,width,height);c.fillStyle="rgba(0,0,0,0.35)";c.fillRect(0,0,width,height)
            if(d&&Math.abs(b.x-a.x)>5&&Math.abs(b.y-a.y)>5){var r=rc();c.clearRect(r.x,r.y,r.width,r.height)}} }

    Rectangle { color:"transparent"; border.color:"#1a73e8"; border.width:2
        visible:d&&Math.abs(b.x-a.x)>5&&Math.abs(b.y-a.y)>5
        x:Math.min(a.x,b.x);y:Math.min(a.y,b.y);width:Math.abs(b.x-a.x);height:Math.abs(b.y-a.y)
        Rectangle { anchors.centerIn:parent; width:lb.implicitWidth+16; height:lb.implicitHeight+10; radius:6; color:"#202124"
            Text { id:lb; anchors.centerIn:parent; color:"#fff"; font.pixelSize:12; font.weight:Font.Medium; font.family:"Segoe UI"
                text:Math.round(parent.parent.width)+" × "+Math.round(parent.parent.height) } } }

    Text { anchors.centerIn:parent; color:"#ccffffff"; font.pixelSize:15; font.weight:Font.Medium; font.family:"Segoe UI"
        text:"Drag to select region  ·  Esc to cancel"; visible:!d }

    MouseArea { anchors.fill:parent; hoverEnabled:true; cursorShape:Qt.CrossCursor
        onPressed:function(m){a=Qt.point(m.x,m.y);b=Qt.point(m.x,m.y);d=true}
        onPositionChanged:function(m){if(d){b=Qt.point(m.x,m.y);cv.requestPaint()}}
        onReleased:function(m){if(d){b=Qt.point(m.x,m.y);d=false;rw.dismiss()
            var r=rc();if(r.width>5&&r.height>5)screenshotManager.captureRegion(r.x,r.y,r.width,r.height)
            else screenshotManager.cancelRegionCapture()}} }

    Shortcut { sequence:"Esc"; onActivated:{rw.dismiss();screenshotManager.cancelRegionCapture()} }
}
