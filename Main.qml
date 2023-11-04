import QtQuick
import QtQuick.Window
import QtLocation
import QtPositioning
import QtQuick.Controls

import Sumo 1.0

Window {
    width: 640
    height: 480
    visible: true
    title: qsTr("Hello World")

    Plugin {
        id: osmPlugin
        name: "osm" // Use the appropriate plugin name
        PluginParameter {
            name: "osm.mapping.providersrepository.disabled"
            value: "true"
        }
        //       PluginParameter {
        //               name: "osm.mapping.host"
        //               value: "http://api.mapbox.com/styles/v1/mfth/clofvg3lt006z01o6ar4s3cbd/tiles/256/{z}/{x}/{y}?access_token=pk.eyJ1IjoibWZ0aCIsImEiOiJjbG9mdmk2Zngwcnd0MmttdjdvdXV4cWZlIn0.nOq4RgmodEc--QDelsaqhw"
        //         }
    }

    Map {
        id: map
        anchors.fill: parent
        plugin: osmPlugin
        activeMapType: supportedMapTypes[supportedMapTypes.length - 4]
        zoomLevel: 16 // Set an initial zoom level to focus on Mulhouse
        center: QtPositioning.coordinate(47.750839,
                                         7.335888) // Set the center to Mulhouse

        onCenterChanged: {
            var minLat = 47.7
            var maxLat = 47.8
            var minLon = 7.2
            var maxLon = 7.5

            var newLat = Math.min(Math.max(center.latitude, minLat), maxLat)
            var newLon = Math.min(Math.max(center.longitude, minLon), maxLon)

            if (newLat !== center.latitude || newLon !== center.longitude) {
                center = QtPositioning.coordinate(newLat, newLon)
            }
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            property point pressPos

            onPressed: {
                pressPos = Qt.point(mouse.x, mouse.y)
            }

            onPositionChanged: {
                var dx = mouse.x - pressPos.x
                var dy = mouse.y - pressPos.y

                var coord = map.toCoordinate(Qt.point(map.width / 2 - dx,
                                                      map.height / 2 - dy))
                map.center = coord

                pressPos = Qt.point(mouse.x, mouse.y)
            }
        }

        property geoCoordinate startCentroid

        PinchHandler {
            id: pinch
            target: null
            onActiveChanged: if (active) {
                                 map.startCentroid = map.toCoordinate(
                                             pinch.centroid.position, false)
                             }
            onScaleChanged: delta => {
                                map.zoomLevel += Math.log2(delta)
                                map.alignCoordinateToPoint(
                                    map.startCentroid, pinch.centroid.position)
                            }
            onRotationChanged: delta => {
                                   map.bearing -= delta
                                   map.alignCoordinateToPoint(
                                       map.startCentroid,
                                       pinch.centroid.position)
                               }
            grabPermissions: PointerHandler.TakeOverForbidden
        }
        WheelHandler {
            id: wheel

            acceptedDevices: Qt.platform.pluginName === "cocoa"
                             || Qt.platform.pluginName
                             === "wayland" ? PointerDevice.Mouse
                                             | PointerDevice.TouchPad : PointerDevice.Mouse
            rotationScale: 1 / 120
            property: "zoomLevel"
        }
    }

    SumoInterface {
        id: sumoInterface
    }

    Component.onCompleted: {
        sumoInterface.startSimulation()
    }

    Timer {
        interval: 300 // Update every second
        running: true
        repeat: true
        onTriggered: {

            //                 console.log("Timer triggered");
            sumoInterface.updateVehiclePositions()
            var positions = sumoInterface.vehiclePositions
            //                 console.log("Vehicle positions:", positions);
            // Update vehicle positions on the map
        }
    }

    Connections {
        target: sumoInterface
    }

    Plugin {
        id: itemsOverlayPlugin
        name: "itemsoverlay"
    }

    Map {
        id: overlayMap
        anchors.fill: parent
        plugin: itemsOverlayPlugin
        center: map.center
        zoomLevel: map.zoomLevel
        color: "transparent"

        // Model for car positions
        //                 ListModel {
        //                     id: carModel
        //                     ListElement { vehid: "veh0"; latitude: 47.750839; longitude: 7.335888 }
        //                     ListElement { vehid: "veh1"; latitude: 47.750839; longitude: 7.335888 }

        //                     function updateVehiclePosition(vehicleId, latitude, longitude) {
        ////                            console.log("im in function", vehicleId);
        //                             let numericPart = vehicleId.match(/\d+/);
        //                             let i = numericPart[0] ?? 0;
        //                             if(i > 100){ return}
        //                                 let item = get(i);
        ////                                 console.log(item.vehid, "is being looked at");
        //                                     setProperty(i, "latitude", latitude);
        //                                     setProperty(i, "longitude", longitude);
        //                                     console.log(vehicleId, " was updated");
        //                                     return;
        //                         }
        //                 }
        MapItemView {
            model: sumoInterface.vehiclePositions

            delegate: MapQuickItem {
                coordinate: QtPositioning.coordinate(modelData.latitude,
                                                     modelData.longitude)
                anchorPoint.x: image.width / 2
                anchorPoint.y: image.height / 1000

                Component.onCompleted: {
                    console.log("Vehicle added:", modelData.latitude,
                                modelData.longitude, modelData.id)
                }

                onCoordinateChanged: {
                    console.log("Vehicle moved:", coordinate.latitude,
                                coordinate.longitude)
                    image.rotation = modelData.rotation + 90
                    //                    if ((modelData.rotation > 45 && modelData.rotation < 130)
                    //                            || (modelData.rotation > -45
                    //                                && modelData.rotation < -130)) {
                    //                        // Modify the 'y' property of the 'translate' element
                    //                        translate.y = "-10px" // Change this value as needed
                    //                    } else {
                    //                        // Reset the 'y' property of the 'translate' element
                    //                        translate.y = 0 // Reset to the original value
                    //                    }
                }

                sourceItem: Image {
                    id: image
                    source: "images/car.png"
                    width: 20
                    height: 20
                    transform: [
                        Rotation {
                            origin.x: image.width / 2
                            origin.y: image.height / 2 - 10
                        },
                        Translate {
                            id: translate
                            y: -10
                            //issue when car is going up and going right
                        }
                    ]
                }
            }
        }

        //HEXAGONS START HERE
        Component {
            id: hexagonComponent
            MapPolygon {
                border.color: 'black'
                border.width: 1
                opacity: 0.7

                property color originalColor: "transparent"

                property int hexagonId: modelData
                property real r: 0.001155
                                 * 2 // The radius of the hexagon, adjust this to change the size
                property real w: Math.sqrt(3) * r // Width of the hexagon
                property real d: 1.5 * r // Adjusted vertical separation between hexagons
                property real row: Math.floor(hexagonId / 13)
                property real col: hexagonId % 13
                property real xOffset: (row % 2) * (w / 2)
                property real centerX: 47.7445 - 0.019 + col * w + xOffset
                property real centerY: 7.3400 - 0.043 + row * d

                function hexVertex(angle) {
                    return QtPositioning.coordinate(
                                centerX + r * Math.sin(angle),
                                centerY + r * Math.cos(angle))
                }

                path: [hexVertex(
                        Math.PI / 3 * 0), hexVertex(Math.PI / 3 * 1), hexVertex(
                        Math.PI / 3 * 2), hexVertex(Math.PI / 3 * 3), hexVertex(
                        Math.PI / 3 * 4), hexVertex(Math.PI / 3 * 5)]
            }
        }

        Repeater {
            id: hexagonRepeater
            model: 312 // Number of hexagons to create
            delegate: hexagonComponent
            Component.onCompleted: {
                console.log("hexagonRepeater is loaded, count:", count)
            }
        }
    }

    // Zoom Controls
    Rectangle {
        width: 50
        height: 100
        color: "lightgray"
        radius: 8
        anchors {
            right: parent.right
            bottom: parent.bottom
            margins: 10
        }

        Column {
            spacing: 5
            anchors.centerIn: parent

            // Zoom In Button
            Button {
                text: "+"
                onClicked: map.zoomLevel += 1
            }

            // Zoom Out Button
            Button {
                text: "-"
                onClicked: map.zoomLevel -= 1
            }
        }
    }

    // Position Display
    Rectangle {
        width: parent.width
        height: 50
        color: "lightgray"
        opacity: 0.7

        Label {
            text: "Latitude: " + map.center.latitude + ", Longitude: " + map.center.longitude
            anchors.centerIn: parent
        }
    }
}
