import QtQuick
import QtQuick.Window
import QtLocation
import QtPositioning
import QtQuick.Controls
import QtQuick.Layouts 1.14

// Rendre le bg des boutons transparents
// Décaler le rectangle des autres options
// Agrandir les boutons suivant la taille de l'écran
// Mettre les autres boutons
// Réussir à arrêter la circulation depuis Qt
import Sumo 1.0

Window {
    id: mainWindow
    width: 640
    height: 480
    visible: true
    title: qsTr("Suivi Voitures")

    property real symbolSize: Math.min(mainWindow.width * 0.05, mainWindow.height * 0.05)

    FontLoader {
        source: "file:///home/elias/TP_PROG/M1IM/Reseaux/c2csim/fontawesome-free-6.4.2-desktop/otfs/Font Awesome 6 Free-Solid-900.otf"
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
    }

    // Zoom Controls
    Rectangle {
        id: rectangleOptions
        width: 50
        height: 100
        color: "transparent"
        border.color: "black"
        radius: 8
        anchors {
            right: parent.right
            top: parent.top
            margins: 10
        }

        Column {
            id: mainColumn
            spacing: 5
            anchors.centerIn: parent

            // To show more options
            Button {
                width:20
                height:20
                text: "\uf0c9"
                font.family: "FontAwesome"
                onClicked: otherOptionsRect.visible = !otherOptionsRect.visible
                // Ajoutez le code ou la logique pour gérer le clic du bouton de menu
            }


            // Zoom In Button
            Button {
                width: 20
                height: 20
                text: "+"
                onClicked: map.zoomLevel += 1
            }

            // Zoom Out Button
            Button {
                width: 20
                height: 20
                text: "-"
                onClicked: map.zoomLevel -= 1
            }
        }
    }

    Rectangle {
        id: otherOptionsRect
        width: 50
        height: parent.height * 0.45
        color: "transparent"
        border.color: "black"
        radius: 8
        visible: false // Initialement invisible
        anchors {
            right: rectangleOptions.left
            top: rectangleOptions.top - 10
            margins: 10
        }

        Column {
            spacing: 5
            anchors.centerIn: parent


            // Zoom In Button
            Button {
                width: 20
                height: 20
                text: "+"
                onClicked: map.zoomLevel += 1
            }

            Button {
                width: 20
                height: 20
                text: "-"
                onClicked: map.zoomLevel -= 1
            }
            // Ajoutez ici le contenu du rectangle du menu, par exemple des boutons supplémentaires, des étiquettes, etc.
        }
    }

    Rectangle {
        id: speedOptions
        width: parent.width * 0.1
        height: parent.height * 0.55
        color: "transparent"
        border.color: "black"
        radius: 8
        anchors {
            right: parent.right
            bottom: parent.bottom
            margins: 10
        }

        Column {
            spacing: speedOptions.height * 0.04
            anchors.centerIn: parent


            // Zoom In Button
            Button {
                width: speedOptions.width* 0.5
                height: speedOptions.height * 0.15
                text: "\uf04a"
                font.family: "FontAwesome"
                font.pixelSize: mainWindow.symbolSize
                onClicked: map.zoomLevel += 1
            }

            Button {
                width: speedOptions.width* 0.5
                height: speedOptions.height * 0.15
                text: "\uf0d9"
                font.family: "FontAwesome"
                font.pixelSize: mainWindow.symbolSize
                onClicked: map.zoomLevel -= 1
            }

            Button {
                id: playButton
                width: speedOptions.width* 0.5
                height: speedOptions.height * 0.15
                text: "\uf04c"
                font.family: "FontAwesome"
                font.pixelSize: mainWindow.symbolSize
                onClicked: {
                    if (playButton.text === "\uf04b")
                    {
                        playButton.text = "\uf04c";
                        // Ajoutez le code à exécuter lorsque la lecture est en pause
                    }
                    else
                    {
                        playButton.text = "\uf04b";
                        // Ajoutez le code à exécuter lorsque la lecture reprend
                    }
                }
            }

            Button {
                width: speedOptions.width* 0.5
                height: speedOptions.height * 0.15
                text: "\uf0da"
                font.family: "FontAwesome"
                font.pixelSize: mainWindow.symbolSize
                onClicked: map.zoomLevel += 1
            }

            Button {
                width: speedOptions.width* 0.5
                height: speedOptions.height * 0.15
                text: "\uf04e"
                font.family: "FontAwesome"
                font.pixelSize: mainWindow.symbolSize
                onClicked: map.zoomLevel -= 1
            }
        }
    }

    // Position Display

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

}
