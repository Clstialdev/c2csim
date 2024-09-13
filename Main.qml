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

    function getHexagonItemById(hexId) {

        // Implémentation pour obtenir l'objet hexagone correspondant à hexagonId
        for (var i = 0; i < hexagonRepeater.count; ++i) {
            var hexagonItem = hexagonRepeater.itemAt(i);
            if (hexagonItem.hexagonId == hexId) {
                return hexagonItem;
            }
        }
        return null;
    }
    function updateHexagonDisplay(hexagonColors) {
        // Met à jour la couleur de l'hexagone dans votre QML
        for (var i = 0; i < hexagonColors.length; ++i) {
            var hexagonInfo = hexagonColors[i];
            var hexagonId = hexagonInfo["id"];
            var colorName = hexagonInfo["couleur"];


            var newHexagonItem = getHexagonItemById(hexagonId);
            if (newHexagonItem !== null) {
                newHexagonItem.updateHexagonColorQML(colorName,hexagonId);
            }
        }
    }
    

    Timer {
        interval: mainWindow.timerInterval// Update every second
        running: true
        repeat: true
        onTriggered: {
            sumoInterface.updateVehiclePositions()
            var positions = sumoInterface.vehiclePositions
            sumoInterface.updateHexagonColor();
            updateHexagonDisplay(sumoInterface.hexagonColors);
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

        MapItemView {
            id:mapItemView
            model: sumoInterface.vehiclePositions

            delegate: MapQuickItem {
                coordinate: QtPositioning.coordinate(modelData.latitude,
                                                     modelData.longitude)
                anchorPoint.x: image.width / 2
                anchorPoint.y: image.height / 1000

                onCoordinateChanged: {
                    image.rotation = modelData.rotation + 90
                }

                sourceItem: Image {
                    id: image

                    // pour changer l'image, aussi rajouter l'image dans le fichier CMakeLists.txt (RESOURCES)
                    //source: "images/car-cropped.svg"
                    Component.onCompleted: {

                        // Appeler la fonction pour appliquer la couleur dès le chargement de la voiture
                        //SumoInterface.applyColorToSVG(modelData.id, modelData.color.toString());
                        sumoInterface.applyColorToSVG(modelData.id.toString());

                        // attention c'est un chemin absolu, à changer
                        source = "file://" + "/home/elias/TP_PROG/M1IM/Reseaux/c2csim/images/generated/car_modified_" + modelData.id + ".svg"
                        //source ="images/generated/car_modified_" + modelData.id + ".svg";
                    }
                    width: 15
                    height: 6
                    transform: [
                        Rotation {
                            origin.x: image.width / 2
                            //origin.y: image.height / 2 - 10 base value origin.y
                            origin.y: image.height - 1;
                        },
                        Translate {
                            id: translate
                            y: -4
                            //issue when car is going up and going right
                        }
                    ]

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            // les boutons personnalisés prennent la valeur de la voiture cliquée
                            carOptionsColumn.current_car_id = modelData.id
                            sumoInterface.showMessage(modelData.id);
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
                color: sumoInterface.hexagonColors[index] ? sumoInterface.hexagonColors[index].couleur : "transparent"


                property int hexagonId: modelData
                property color hexTestColor:"transparent"
                property real r: 0.001155 * 2 // The radius of the hexagon, adjust this to change the size
                property real w: Math.sqrt(3) * r // Width of the hexagon
                property real d: 1.5 * r // Adjusted vertical separation between hexagons
                property real row: Math.floor(hexagonId / 13)
                property real col: hexagonId % 13;
                property real xOffset: (row % 2) * (w / 2);
                property real centerX: 47.7445 - 0.019 + col * w + xOffset;
                property real centerY: 7.3400 - 0.043 + row * d


                Component.onCompleted: {
                    sumoInterface.addHexagon(modelData.toString(),centerX,centerY);
                }
                
                // partie finale du processus de changement de couleur, appelé par
                //la fonction onUpdateHexagonColor un peu plus haut dans le code
                function updateHexagonColorQML(hexagonColor,hexId) {
                    if(hexId == hexagonId){

                        color = hexagonColor; // Met à jour la couleur de l'hexagone
                        hexTestColor = hexagonColor;
                    }
                }

                function hexVertex(angle)
                {
                    return QtPositioning.coordinate(
                                centerX + r * Math.sin(angle),
                                centerY + r * Math.cos(angle));
                }

                path: [hexVertex(
                        Math.PI / 3 * 0), hexVertex(Math.PI / 3 * 1), hexVertex(
                        Math.PI / 3 * 2), hexVertex(Math.PI / 3 * 3), hexVertex(
                        Math.PI / 3 * 4), hexVertex(Math.PI / 3 * 5)]
            }

        }

        Repeater {
            id: hexagonRepeater
            model: 312 // Utilisez la taille de hexagonColors comme modèle
            delegate: hexagonComponent
            Component.onCompleted: {
            }

            onModelChanged: {
                // Mets à jour la taille du modèle lorsqu'elle change
                model = sumoInterface.hexagonColors.length;
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
                        font.family: fontAwesomeLoaded ? fontAwesome.name : "FontAwesome"
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
        width: parent.width * 0.08
        height: parent.height * 0.45
        color: "transparent"
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
            anchors {
                right: parent.right
                top: parent.top
                margins: 10
            }
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
                        font.family: fontAwesomeLoaded ? fontAwesome.name : "FontAwesome"
                        font.pixelSize: mainWindow.symbolSize
                        color:"#A1DC30"
                    }
                }
                onClicked: {
                    if(carOptionsColumn.current_car_id.toString() != ""){
                        sumoInterface.changeSpeedCar(carOptionsColumn.current_car_id.toString(), 1.0); //-1 réinitialise la vitesse par Sumo
                        console.log("ralentissement de la voiture "+carOptionsColumn.current_car_id);
                    } else {
                        console.log("Aucune voiture sélectionnée.");
                    }
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
                        font.family: fontAwesomeLoaded ? fontAwesome.name : "FontAwesome"
                        font.pixelSize: mainWindow.symbolSize
                        color:"#A1DC30"
                    }
                }
                onClicked: {
                    if(carOptionsColumn.current_car_id.toString() != ""){
                        sumoInterface.changeSpeedCar(carOptionsColumn.current_car_id.toString(), 0.0); //-1 réinitialise la vitesse par Sumo
                        console.log("arrêt de la voiture "+carOptionsColumn.current_car_id);
                    } else {
                        console.log("Aucune voiture sélectionnée.");
                    }
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
                        font.family: fontAwesomeLoaded ? fontAwesome.name : "FontAwesome"
                        font.pixelSize: mainWindow.symbolSize
                        color:"#A1DC30"
                    }
                }
                onClicked: {
                    if(carOptionsColumn.current_car_id.toString() != ""){
                        sumoInterface.changeSpeedCar(carOptionsColumn.current_car_id.toString(), -1); //-1 réinitialise la vitesse par Sumo
                        console.log("redémarrage de la voiture "+carOptionsColumn.current_car_id);
                    } else {
                        console.log("Aucune voiture sélectionnée.");
                    }
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
                        font.family: fontAwesomeLoaded ? fontAwesome.name : "FontAwesome"
                        font.pixelSize: mainWindow.symbolSize
                        color:"#A1DC30"
                    }
                }
                onClicked: {
                    if(carOptionsColumn.current_car_id.toString() != ""){
                        sumoInterface.changeSpeedCar(carOptionsColumn.current_car_id.toString(), 30.0); //-1 réinitialise la vitesse par Sumo
                        console.log("accélération de la voiture "+carOptionsColumn.current_car_id);
                    } else {
                        console.log("Aucune voiture sélectionnée.");
                        // Ajoutez d'autres actions si nécessaire
                    }
                }
                
            }
        }
        Column {
            id: broadcastColumn
            spacing: speedOptions.height * 0.03
            anchors {
                right: parent.left
                top: parent.top
                margins: 10
            }

            TextField {
                id: myTextField
                width: speedOptions.width *1.2
                height: speedOptions.height * 0.12
                placeholderText: "Saisissez votre message"
                onAccepted: {
                    var texteSaisi = myTextField.text;
                    if (carOptionsColumn.current_car_id.toString() !== "") {
                        sumoInterface.findCarsAffectedByFrequency(carOptionsColumn.current_car_id.toString(), texteSaisi);
                        console.log("Recherche des voitures affectées par la fréquence de la voiture " + carOptionsColumn.current_car_id);

                        var vehicles = sumoInterface.stringArray;
                        console.log("Véhicules à proximité:", vehicles);
                        
                    } else {
                        console.log("Aucune voiture sélectionnée.");
                    }
                }
            }
        }

    }

    Rectangle {
        id: speedOptions
        width: parent.width * 0.1
        height: parent.height * 0.55
        color: "transparent"
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
                        font.family: fontAwesomeLoaded ? fontAwesome.name : "FontAwesome"
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
                        font.family: fontAwesomeLoaded ? fontAwesome.name : "FontAwesome"
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
                        font.family: fontAwesomeLoaded ? fontAwesome.name : "FontAwesome"
                        font.pixelSize: mainWindow.symbolSize
                        color:"#A1DC30"
                    }
                }

                onClicked: {
                    if (playButtonText.text === "\uf04b")
                    {
                        playButtonText.text = "\uf04c";
                        mainWindow.timerInterval = 300;
                        mainWindow.coeffVitesse = 1
                    }
                    else {
                        playButtonText.text = "\uf04b";
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
                        font.family: fontAwesomeLoaded ? fontAwesome.name : "FontAwesome"
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
                        font.family: fontAwesomeLoaded ? fontAwesome.name : "FontAwesome"
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
            font.family: fontAwesomeLoaded ? fontAwesome.name : "FontAwesome"
            font.pixelSize: mainWindow.symbolSize * 0.5
            anchors.centerIn: parent
            color:"#A1DC30"
        }
    }
}
