import QtQuick
import QtQuick.Shapes
import "PanelStyle.js" as PanelStyle

Item {
    id: surface
    required property var hostWindow
    property color color: hostWindow.background
    property string edge: hostWindow.barEdge
    readonly property int contentInset: PanelStyle.surfaceInset
    readonly property bool vertical: edge === "left" || edge === "right"
    readonly property real progress: hostWindow.revealProgress
    readonly property bool flushLeading: vertical ? hostWindow.y <= 0 : hostWindow.x <= 0
    readonly property bool flushTrailing: hostWindow.parent && (vertical
        ? hostWindow.y + hostWindow.height >= hostWindow.parent.height
        : hostWindow.x + hostWindow.width >= hostWindow.parent.width)
    // Concave joins inset the painted body except at a flush screen edge.
    // Pad relative to that body, not the larger rectangular attachment area.
    readonly property int leadingBodyInset: flushLeading ? 0 : contentInset
    readonly property int trailingBodyInset: flushTrailing ? 0 : contentInset
    default property alias panelContent: contents.data

    data: [Item {
        id: reveal
        width: surface.vertical ? surface.width * surface.progress : surface.width
        height: surface.vertical ? surface.height : surface.height * surface.progress
        x: surface.edge === "right" ? surface.width - width : 0
        y: surface.edge === "bottom" ? surface.height - height : 0
        clip: true

        Shape {
            id: outline
            width: surface.vertical ? reveal.height : reveal.width
            height: surface.vertical ? reveal.width : reveal.height
            x: surface.edge === "bottom" || surface.edge === "right" ? reveal.width : 0
            y: surface.edge === "bottom" || surface.edge === "left" ? reveal.height : 0
            transform: Rotation {
                angle: surface.edge === "bottom" ? 180 : surface.edge === "left" ? -90 : surface.edge === "right" ? 90 : 0
            }
            antialiasing: true
            // Scene-graph geometry stays reactive even while hidden; unlike a
            // Canvas texture, it cannot miss a theme/color repaint request.
            ShapePath {
                strokeWidth: -1
                fillColor: surface.color
                PathSvg { path: {
                var w = outline.width;
                var h = outline.height;
                if (w <= 0 || h <= 0) return "";
                var r = Math.min(surface.contentInset, w / 4, h / 2);
                var reversed = surface.edge === "bottom" || surface.edge === "left";
                var startInset = (reversed ? surface.flushTrailing : surface.flushLeading) ? 0 : r;
                var endInset = (reversed ? surface.flushLeading : surface.flushTrailing) ? 0 : r;
                // The two inward curves join the sheet to the bar; the outer
                // corners remain rounded as the sheet unfolds.
                return "M 0 0 L " + w + " 0 Q " + (w-endInset) + " 0 " + (w-endInset) + " " + endInset
                    + " L " + (w-endInset) + " " + (h-endInset) + " Q " + (w-endInset) + " " + h + " " + (w-2*endInset) + " " + h
                    + " L " + (2*startInset) + " " + h + " Q " + startInset + " " + h + " " + startInset + " " + (h-startInset)
                    + " L " + startInset + " " + startInset + " Q " + startInset + " 0 0 0 Z";
                } }
            }
        }

        Item {
            id: contents
            objectName: "panelContentFrame"
            width: Math.max(0, surface.width - surface.contentInset * 2)
            height: Math.max(0, surface.height - surface.contentInset * 2)
            x: surface.contentInset + (surface.vertical ? 0 : (surface.leadingBodyInset - surface.trailingBodyInset) / 2) + (surface.edge === "right" ? reveal.width - surface.width : 0)
            y: surface.contentInset + (surface.vertical ? (surface.leadingBodyInset - surface.trailingBodyInset) / 2 : 0) + (surface.edge === "bottom" ? reveal.height - surface.height : 0)
            opacity: Math.min(1, surface.progress * 2)
        }
    }]
}
