import QtQuick
import QtQuick.Window
import QtLocation
import QtPositioning
import QtQuick.Controls

import Sumo 1.0

Window {
    id: mainWindow
    width: 1440
    height: 800
    visible: true
    title: qsTr("Suivi Voitures")

    property bool fontAwesomeLoaded: false;

        property int timerInterval: 300 // pour pouvoir la modifier facilement
            property real coeffVitesse: 1


                property real symbolSize: Math.min(mainWindow.width * 0.05, mainWindow.height * 0.05)

                FontLoader {
                    id: fontAwesome
                    source: "fonts/fa.otf"
                    onStatusChanged: fontAwesomeLoaded = (status === FontLoader.Ready)
                }

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

                        if (newLat !== center.latitude || newLon !== center.longitude)
                        {
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
                    interval: mainWindow.timerInterval// Update every second
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
                                //console.log("Vehicle added:", modelData.latitude, modelData.longitude, modelData.id)
                            }

                            onCoordinateChanged: {
                                //console.log("Vehicle moved:", coordinate.latitude, coordinate.longitude)
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

                                MouseArea {

                                    anchors.fill: parent
                                    onClicked: {
                                        // les boutons personnalisés prennent la valeur de la voiture cliquée
                                        carOptionsColumn.current_car_id = modelData.id
                                        console.log("-------------------");

                                    }

                                }

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
                                                property real col: hexagonId % 13;
                                                    property real xOffset: (row % 2) * (w / 2)
                                                    property real centerX: 47.7445 - 0.019 + col * w + xOffset
                                                        property real centerY: 7.3400 - 0.043 + row * d

                                                            function hexVertex(angle)
                                                            {
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
                                                                    id: rectangleOptions
                                                                    width: parent.width * 0.1
                                                                    height: parent.height * 0.3
                                                                    color: "transparent"
                                                                    //border.color: "blue"
                                                                    radius: 8
                                                                    anchors {
                                                                        right: parent.right
                                                                        top: parent.top
                                                                        margins: 10
                                                                    }

                                                                    Column {
                                                                        id: mainColumn
                                                                        spacing: speedOptions.height * 0.04
                                                                        anchors.centerIn: parent

                                                                        // To show more options
                                                                        Button {
                                                                            width: speedOptions.width * 0.55
                                                                            height: speedOptions.height * 0.15
                                                                            background: Rectangle {
                                                                                color: "black"
                                                                                border.color: "#26282a"
                                                                                border.width: 1
                                                                                radius: 4
                                                                                Text {
                                                                                    anchors.centerIn: parent
                                                                                    text: "\uf1b9"
                                                                                    font.family: fontAwesomeLoaded ? fontAwesomeLoader.name : "FontAwesome"
                                                                                    font.pixelSize: mainWindow.symbolSize
                                                                                    color:"#A1DC30"
                                                                                }
                                                                            }
                                                                            onClicked: otherOptionsRect.visible = !otherOptionsRect.visible
                                                                        }

                                                                        // Zoom In Button
                                                                        Button {
                                                                            width: speedOptions.width * 0.55
                                                                            height: speedOptions.height * 0.15
                                                                            background: Rectangle {
                                                                                color: "black"
                                                                                border.color: "#26282a"
                                                                                border.width: 1
                                                                                radius: 4
                                                                                Text {
                                                                                    anchors.centerIn: parent
                                                                                    text: "+"
                                                                                    font.pixelSize: mainWindow.symbolSize
                                                                                    color:"#A1DC30"
                                                                                }
                                                                            }
                                                                            onClicked: map.zoomLevel += 1
                                                                        }

                                                                        // Zoom Out Button
                                                                        Button {
                                                                            width: speedOptions.width * 0.55
                                                                            height: speedOptions.height * 0.15
                                                                            background: Rectangle {
                                                                                color: "black"
                                                                                border.color: "#26282a"
                                                                                border.width: 1
                                                                                radius: 4
                                                                                Text {
                                                                                    anchors.centerIn: parent
                                                                                    text: "-"
                                                                                    font.pixelSize: mainWindow.symbolSize
                                                                                    color:"#A1DC30"
                                                                                }
                                                                            }
                                                                            onClicked: map.zoomLevel -= 1
                                                                        }
                                                                    }
                                                                }

                                                                Rectangle {
                                                                    id: otherOptionsRect
                                                                    width: parent.width * 0.1
                                                                    height: parent.height * 0.45
                                                                    color: "transparent"
                                                                    //border.color: "red"
                                                                    radius: 8
                                                                    visible: false
                                                                    anchors {
                                                                        right: rectangleOptions.left
                                                                        top: parent.top + 10
                                                                        margins: 10
                                                                    }

                                                                    Column {
                                                                        id: carOptionsColumn
                                                                        spacing: speedOptions.height * 0.04
                                                                        anchors.centerIn: parent
                                                                        property string current_car_id: "";

                                                                            // << Button pour la voiture
                                                                            Button {
                                                                                width: speedOptions.width * 0.55
                                                                                height: speedOptions.height * 0.15

                                                                                background: Rectangle {
                                                                                    color: "black"
                                                                                    border.color: "#26282a"
                                                                                    border.width: 1
                                                                                    radius: 4
                                                                                    Text {
                                                                                        anchors.centerIn: parent
                                                                                        text: "\uf04a"
                                                                                        font.family: fontAwesomeLoaded ? fontAwesomeLoader.name : "FontAwesome"
                                                                                        font.pixelSize: mainWindow.symbolSize
                                                                                        color:"#A1DC30"
                                                                                    }
                                                                                }
                                                                                onClicked: {
                                                                                    sumoInterface.changeSpeedCar(carOptionsColumn.current_car_id.toString(), 1.0); //-1 réinitialise la vitesse par Sumo
                                                                                    console.log("ralentissement de la voiture "+carOptionsColumn.current_car_id);
                                                                                }
                                                                            }

                                                                            // stoppe voiture
                                                                            Button {
                                                                                id: restartCarButton
                                                                                width: speedOptions.width * 0.55
                                                                                height: speedOptions.height * 0.15
                                                                                background: Rectangle {
                                                                                    color: "black"
                                                                                    border.color: "#26282a"
                                                                                    border.width: 1
                                                                                    radius: 4
                                                                                    Text {
                                                                                        anchors.centerIn: parent
                                                                                        text: "\uf04c"
                                                                                        font.family: fontAwesomeLoaded ? fontAwesomeLoader.name : "FontAwesome"
                                                                                        font.pixelSize: mainWindow.symbolSize
                                                                                        color:"#A1DC30"
                                                                                    }
                                                                                }
                                                                                onClicked: {
                                                                                    sumoInterface.changeSpeedCar(carOptionsColumn.current_car_id.toString(), 0.0);
                                                                                    console.log("arrêt de la voiture "+carOptionsColumn.current_car_id);
                                                                                }
                                                                            }

                                                                            // redémarre voiture
                                                                            Button {
                                                                                id: stopCarButton
                                                                                width: speedOptions.width * 0.55
                                                                                height: speedOptions.height * 0.15
                                                                                background: Rectangle {
                                                                                    color: "black"
                                                                                    border.color: "#26282a"
                                                                                    border.width: 1
                                                                                    radius: 4

                                                                                    Text {
                                                                                        anchors.centerIn: parent
                                                                                        text: "\uf04b"
                                                                                        font.family: fontAwesomeLoaded ? fontAwesomeLoader.name : "FontAwesome"
                                                                                        font.pixelSize: mainWindow.symbolSize
                                                                                        color:"#A1DC30"
                                                                                    }
                                                                                }
                                                                                onClicked: {
                                                                                    sumoInterface.changeSpeedCar(carOptionsColumn.current_car_id.toString(), -1); //-1 réinitialise la vitesse par Sumo
                                                                                    console.log("redémarrage de la voiture "+carOptionsColumn.current_car_id);
                                                                                }
                                                                            }
                                                                            // >> Button pour la voiture
                                                                            Button {
                                                                                width: speedOptions.width * 0.55
                                                                                height: speedOptions.height * 0.15

                                                                                background: Rectangle {
                                                                                    color: "black"
                                                                                    border.color: "#26282a"
                                                                                    border.width: 1
                                                                                    radius: 4
                                                                                    Text {
                                                                                        anchors.centerIn: parent
                                                                                        text: "\uf04e"
                                                                                        font.family: fontAwesomeLoaded ? fontAwesomeLoader.name : "FontAwesome"
                                                                                        font.pixelSize: mainWindow.symbolSize
                                                                                        color:"#A1DC30"
                                                                                    }
                                                                                }
                                                                                onClicked: {
                                                                                    sumoInterface.changeSpeedCar(carOptionsColumn.current_car_id.toString(), 30.0); //-1 réinitialise la vitesse par Sumo
                                                                                    console.log("accélération de la voiture "+carOptionsColumn.current_car_id);
                                                                                }
                                                                            }
                                                                        }
                                                                    }

                                                                    Rectangle {
                                                                        id: speedOptions
                                                                        width: parent.width * 0.1
                                                                        height: parent.height * 0.55
                                                                        color: "transparent"
                                                                        //border.color: "black"
                                                                        radius: 8
                                                                        anchors {
                                                                            right: parent.right
                                                                            bottom: parent.bottom
                                                                            margins: 10
                                                                        }

                                                                        Column {
                                                                            spacing: speedOptions.height * 0.04
                                                                            anchors.centerIn: parent

                                                                            // << Button
                                                                            Button {
                                                                                width: speedOptions.width * 0.55
                                                                                height: speedOptions.height * 0.15

                                                                                background: Rectangle {
                                                                                    color: "black"
                                                                                    border.color: "#26282a"
                                                                                    border.width: 1
                                                                                    radius: 4
                                                                                    Text {
                                                                                        anchors.centerIn: parent
                                                                                        text: "\uf04a"
                                                                                        font.family: fontAwesomeLoaded ? fontAwesomeLoader.name : "FontAwesome"
                                                                                        font.pixelSize: mainWindow.symbolSize
                                                                                        color:"#A1DC30"
                                                                                    }
                                                                                }
                                                                                onClicked: {
                                                                                    mainWindow.timerInterval = 600
                                                                                    mainWindow.coeffVitesse = 0.25
                                                                                }
                                                                            }
                                                                            // < Button
                                                                            Button {
                                                                                width: speedOptions.width * 0.55
                                                                                height: speedOptions.height * 0.15
                                                                                background: Rectangle {
                                                                                    color: "black"
                                                                                    border.color: "#26282a"
                                                                                    border.width: 1
                                                                                    radius: 4
                                                                                    Text {
                                                                                        anchors.centerIn: parent
                                                                                        text: "\uf0d9"
                                                                                        font.family: fontAwesomeLoaded ? fontAwesomeLoader.name : "FontAwesome"
                                                                                        font.pixelSize: mainWindow.symbolSize
                                                                                        color:"#A1DC30"
                                                                                    }
                                                                                }
                                                                                onClicked: {
                                                                                    mainWindow.timerInterval = 450
                                                                                    mainWindow.coeffVitesse = 0.5
                                                                                }
                                                                            }

                                                                            // Play/Pause Button
                                                                            Button {
                                                                                id: playButton
                                                                                width: speedOptions.width * 0.55
                                                                                height: speedOptions.height * 0.15
                                                                                background: Rectangle {
                                                                                    color: "black"
                                                                                    border.color: "#26282a"
                                                                                    border.width: 1
                                                                                    radius: 4
                                                                                    Text {
                                                                                        id: playButtonText
                                                                                        anchors.centerIn: parent
                                                                                        text: "\uf04c"
                                                                                        font.family: fontAwesomeLoaded ? fontAwesomeLoader.name : "FontAwesome"
                                                                                        font.pixelSize: mainWindow.symbolSize
                                                                                        color:"#A1DC30"
                                                                                    }
                                                                                }

                                                                                onClicked: {
                                                                                    if (playButtonText.text === "\uf04b")
                                                                                    {
                                                                                        playButtonText.text = "\uf04c";
                                                                                        // Add logic for when playback is paused
                                                                                        mainWindow.timerInterval = 300;
                                                                                        mainWindow.coeffVitesse = 1
                                                                                    }
                                                                                    else {
                                                                                        playButtonText.text = "\uf04b";
                                                                                        // Add logic for when playback resumes
                                                                                        mainWindow.timerInterval = 100000;
                                                                                        mainWindow.coeffVitesse = 0
                                                                                    }
                                                                                }
                                                                            }
                                                                            // > Button
                                                                            Button {
                                                                                width: speedOptions.width * 0.55
                                                                                height: speedOptions.height * 0.15
                                                                                background: Rectangle {
                                                                                    color: "black"
                                                                                    border.color: "#26282a"
                                                                                    border.width: 1
                                                                                    radius: 4
                                                                                    Text {
                                                                                        anchors.centerIn: parent
                                                                                        text: "\uf0da"
                                                                                        font.family: fontAwesomeLoaded ? fontAwesomeLoader.name : "FontAwesome"
                                                                                        font.pixelSize: mainWindow.symbolSize
                                                                                        color:"#A1DC30"
                                                                                    }
                                                                                }
                                                                                onClicked: {
                                                                                    mainWindow.timerInterval = 150
                                                                                    mainWindow.coeffVitesse = 2
                                                                                }
                                                                            }
                                                                            // >> Button
                                                                            Button {
                                                                                width: speedOptions.width * 0.55
                                                                                height: speedOptions.height * 0.15
                                                                                background: Rectangle {
                                                                                    color: "black"
                                                                                    border.color: "#26282a"
                                                                                    border.width: 1
                                                                                    radius: 4
                                                                                    Text {
                                                                                        anchors.centerIn: parent
                                                                                        text: "\uf04e"
                                                                                        font.family: fontAwesomeLoaded ? fontAwesomeLoader.name : "FontAwesome"
                                                                                        font.pixelSize: mainWindow.symbolSize
                                                                                        color:"#A1DC30"
                                                                                    }
                                                                                }
                                                                                onClicked: {
                                                                                    mainWindow.timerInterval = 75
                                                                                    mainWindow.coeffVitesse = 4
                                                                                }

                                                                            }
                                                                        }
                                                                    }

                                                                    Rectangle {
                                                                        id: speedRectangle
                                                                        width: 0.08 * parent.width
                                                                        height: 0.55 * 0.15 * parent.height
                                                                        color: "black"
                                                                        border.color: "black"
                                                                        radius: 8

                                                                        anchors {
                                                                            right: parent.right
                                                                            bottom: parent.bottom
                                                                        }
                                                                        anchors.rightMargin: 0.1 * parent.width
                                                                        anchors.bottomMargin: 0.245* parent.height

                                                                        Label {
                                                                            text: "\uf017 : x" + mainWindow.coeffVitesse
                                                                            font.family: fontAwesomeLoaded ? fontAwesomeLoader.name : "FontAwesome"
                                                                            font.pixelSize: mainWindow.symbolSize * 0.5
                                                                            anchors.centerIn: parent
                                                                            color:"#A1DC30"
                                                                        }
                                                                    }

                                                                    /* // Position Display
                                                                    Rectangle {
                                                                        width: 0.75 * parent.width
                                                                        height: 50
                                                                        color: "lightgray"
                                                                        opacity: 0.7

                                                                        anchors {
                                                                            top: parent.top
                                                                            left: parent.left
                                                                        }

                                                                        Label {
                                                                            text: "Latitude: " + map.center.latitude + ", Longitude: " + map.center.longitude
                                                                            anchors.centerIn: parent
                                                                        }
                                                                    }
                                                                    */
                                                                }
