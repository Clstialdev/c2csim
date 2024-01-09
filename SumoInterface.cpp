#include "headers/SumoInterface.h"
#include <iostream>
#include <string>
#include <QObject>
#include <QDebug>
#include <QColor>
#include <QRandomGenerator>
#include <QFile>
#include <QSvgRenderer>
#include <QPixmap>
#include <QPainter>
#include <QCoreApplication>
#include <QIcon>
#include <cmath>

#include "geoconverter.h"

SumoInterface::SumoInterface(QObject *parent) : QObject(parent)
{
    qRegisterMetaType<QString>("QString");
    // Initialize SUMO connection here if necessary
}

SumoInterface::~SumoInterface()
{
    // Cleanup SUMO connection here if necessary
    traci.close();
}

void SumoInterface::startSimulation()
{
    // Connect to SUMO
    traci.connect("localhost", 6066);
}

void SumoInterface::stopSimulation()
{
    // Close the SUMO connection
    traci.close();
}

QColor SumoInterface::applyColor(const QString &idString)
{
    if (vehicleColors.contains(idString))
    {
        // Si oui, retourne la couleur existante
        return vehicleColors.value(idString);
    }
    else
    {
        // Sinon, génère une nouvelle couleur aléatoire, associe-la à l'ID de la voiture, puis retourne la couleur
        QColor randomColor = QColor::fromRgb(QRandomGenerator::global()->bounded(256),
                                             QRandomGenerator::global()->bounded(256),
                                             QRandomGenerator::global()->bounded(256));
        vehicleColors.insert(idString, randomColor);

        return randomColor;
    }
}

void SumoInterface::showMessage(const QString &targetId)
{
    bool foundCar = false;
    for (const QVariant &vehicleVariant : vehiclePositions)
    {
        QVariantMap vehicleMap = vehicleVariant.toMap();
        QString currentId = vehicleMap["id"].toString();

        if (currentId == targetId)
        {
            qDebug() << "Dernier message enregistré par la voiture " << vehicleMap["id"].toString() << ": " << vehicleMap["message"].toString();
            foundCar = true;
        }
    }
    if (!foundCar)
    {
        qDebug() << "Le véhicule avec l'ID" << targetId << "n'a pas été trouvé dans vehiclePositions.";
    }
}

void SumoInterface::convertToArray()
{
    stringArray.clear();
    // Parcourir vehiclesInRange et ajouter currentID au tableau de chaînes de caractères
    for (const auto &id : vehiclesInRange.keys())
    {
        stringArray.append(id);
    }

    emit vehiclesInRangeChanged();
}

/***
 * @return ancienne vitesse de la voiture
 * @def modifie la vitesse d'une voiture ou met à l'arrêt
 */
void SumoInterface::changeSpeedCar(const QVariant &vehicleID, double speed)
{
    QString idString = vehicleID.toString();
    qDebug() << "Vehicle ID:" << idString << "New Speed:" << speed;
    traci.vehicle.setSpeed(idString.toStdString(), speed);
}

// crée des images svg de couleur différentes (une pour chaque voiture)
// et les places dans le dossier images/generated
void SumoInterface::applyColorToSVG(const QString &id)
{
    QColor carColor = applyColor(id);
    QString colorString = carColor.name(); // Obtenir le nom de la couleur (par exemple, "#RRGGBB")

    /*
    Charger le fichier SVG
    Si la ligne de chemin ne fonctionne pas, utiliser un chemin absolu comme ceci:
    QString originalFilePath = "/home/elias/TP_PROG/M1IM/Reseaux/c2csim/images/car-cropped.svg";
    */
    QString originalFilePath = QCoreApplication::applicationDirPath() + "/images/car-cropped.svg";

    QFile file(originalFilePath);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text))
    {
        qDebug() << "Erreur lors de l'ouverture du fichier SVG";
        return;
    }

    QTextStream in(&file);
    QString svgContent = in.readAll();
    file.close();

    // Modifier la couleur dans le fichier SVG
    svgContent.replace("fill=\"#000000\"", "fill=\"" + colorString + "\"");

    /*
    Charger le fichier SVG
    Si la ligne de chemin ne fonctionne pas, utiliser un chemin absolu comme ceci:
    QString uniqueFileName = "/home/elias/TP_PROG/M1IM/Reseaux/c2csim/images/generated/car_modified_" + id + ".svg";
    */
    QString uniqueFileName = QCoreApplication::applicationDirPath() + "/images/generated/car_modified_" + id + ".svg";
    //  Sauvegarder le fichier SVG modifié avec un nom de fichier unique
    QFile modifiedFile(uniqueFileName);
    if (!modifiedFile.open(QIODevice::WriteOnly | QIODevice::Text))
    {
        qDebug() << "Erreur lors de la création du fichier SVG modifié";
        return;
    }

    QTextStream out(&modifiedFile);
    out << svgContent;
    modifiedFile.close();
}

double SumoInterface::recupVitesse(const QVariant &vehicleID)
{
    QString idString = vehicleID.toString();

    return traci.vehicle.getSpeed(idString.toStdString());
}

double SumoInterface::calculateSignalStrength(double distance, double signalStrengthAtOneMeter)
{
    if (distance == 0)
        return std::numeric_limits<double>::max();
    return signalStrengthAtOneMeter / (distance * distance);
}

// Function to convert degrees to radians
constexpr double SumoInterface::degreesToRadians(double degrees)
{
    return degrees * M_PI / 180.0;
}

// Haversine formula to calculate the distance between two points on the Earth
double SumoInterface::distanceBetweenPoints(double lat1, double lon1, double lat2, double lon2)
{
    constexpr double earthRadiusKm = 6371.0; // Earth's radius in kilometers

    double lat1Rad = degreesToRadians(lat1);
    double lat2Rad = degreesToRadians(lat2);
    double deltaLat = degreesToRadians(lat2 - lat1);
    double deltaLon = degreesToRadians(lon2 - lon1);

    double a = sin(deltaLat / 2) * sin(deltaLat / 2) +
               cos(lat1Rad) * cos(lat2Rad) *
                   sin(deltaLon / 2) * sin(deltaLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadiusKm * c;
}

// regarde pour chaque hexagone si il y a une voiture dedans
// si il y a une voiture dedans, on récupère la couleur de la voiture,
// et on la met en argument du signal qu'on envoie au fichier main.qml
void SumoInterface::updateHexagonColor()
{
    QVariantList newHexagonColors;
    QMap<QString, QString> carColors;

    double minAcceptableSignalStrength = 10.0; // Define the minimum acceptable signal strength

    // Initialize all hexagons to transparent
    for (const QVariant &hexagonVariant : listHexagons)
    {
        QVariantMap hexagonMap = hexagonVariant.toMap();
        newHexagonColors.append(QVariantMap{{"id", hexagonMap["id"].toString()}, {"couleur", "transparent"}});
    }

    // Parcours de la liste des voitures
    for (const QVariant &voitureVariant : vehiclePositions)
    {
        QVariantMap voitureMap = voitureVariant.toMap();
        qreal voitureLat = voitureMap["latitude"].toReal();
        qreal voitureLon = voitureMap["longitude"].toReal();
        QVariant carColorVariant = voitureMap["color"];
        QColor color = carColorVariant.value<QColor>();
        QString colorName = color.name();
        double signalStrengthAtOneMeter = voitureMap["strength"].toDouble();

        // Check which hexagon this car is in
        for (QVariant &hexagonVariant : listHexagons)
        {
            QVariantMap hexagonMap = hexagonVariant.toMap();
            qreal hexagonLatCenter = hexagonMap["latCenter"].toReal();
            qreal hexagonLonCenter = hexagonMap["lonCenter"].toReal();
            QString hexagonId = hexagonMap["id"].toString();
            double hexagonStrength = hexagonMap["current_strength"].toDouble();

            double distance = distanceBetweenPoints(voitureLat, voitureLon, hexagonLatCenter, hexagonLonCenter);

            double signalStrength = calculateSignalStrength(distance, signalStrengthAtOneMeter);

            // qDebug() << "ID véhicule: " << voitureMap["id"].toString() << " ID de l'hexagone: " << hexagonId << " et signal strength: " << signalStrength;

            // Comparison to the current signal
            if ((signalStrength >= hexagonStrength) || (hexagonMap["current_car"] == voitureMap["id"].toString()))
            {
                hexagonMap["current_car"] = voitureMap["id"].toString(); // on retient la voiture qui impose sa fréquence
                hexagonMap["current_strength"] = signalStrength;
                hexagonVariant = hexagonMap; // Update the value in the list
                // Update the color of the hexagon with the color of the car
                carColors[hexagonId] = colorName;
            }
        }
    }

    // Now update the hexagon colors based on the cars
    for (int i = 0; i < newHexagonColors.size(); ++i)
    {
        QVariantMap hexColorVariantMap = newHexagonColors[i].toMap();
        QString hexagonId = hexColorVariantMap["id"].toString();
        if (carColors.contains(hexagonId))
        {
            hexColorVariantMap["couleur"] = carColors[hexagonId];
            newHexagonColors[i] = hexColorVariantMap;
        }
    }

    if (newHexagonColors != hexagonColors)
    {
        hexagonColors = newHexagonColors;
        emit hexagonColorsChanged();
    }
}

// regarde si une voiture est dans un certain hexagone
bool SumoInterface::isPointInsideHexagon(qreal pointLat, qreal pointLon, qreal hexagonLatCenter, qreal hexagonLonCenter)
{
    qreal radius = 0.0025; // Adjust this value to fit your hexagons

    // Calculate the vertices of the hexagon
    QList<QPointF> hexagonVertices;
    for (int i = 0; i < 6; ++i)
    {
        qreal angle = 60 * i - 30;
        qreal x = hexagonLatCenter + radius * qCos(qDegreesToRadians(angle));
        qreal y = hexagonLonCenter + radius * qSin(qDegreesToRadians(angle));
        hexagonVertices.append(QPointF(x, y));
    }

    // Use the ray casting algorithm to determine if the point is inside the hexagon
    int i, j, nvert = hexagonVertices.size();
    bool inside = false;
    for (i = 0, j = nvert - 1; i < nvert; j = i++)
    {
        if (((hexagonVertices[i].y() > pointLon) != (hexagonVertices[j].y() > pointLon)) &&
            (pointLat < (hexagonVertices[j].x() - hexagonVertices[i].x()) * (pointLon - hexagonVertices[i].y()) / (hexagonVertices[j].y() - hexagonVertices[i].y()) + hexagonVertices[i].x()))
        {
            inside = !inside;
        }
    }

    return inside;
}

// on crée une liste contenant les id et coordonnées des hexagones
// pour pouvoir les utiliser dans ce fichier plus facilement
void SumoInterface::addHexagon(const QString &idHex, qreal xCenter, qreal yCenter)
{

    QVariantMap hexagonMap;
    hexagonMap["id"] = idHex;

    hexagonMap["latCenter"] = xCenter;
    hexagonMap["lonCenter"] = yCenter;
    hexagonMap["current_strength"] = 8;
    hexagonMap["current_car"] = "";

    listHexagons.append(hexagonMap);
}

QVariantList SumoInterface::getVehiclePositions() const
{
    return vehiclePositions;
}

QVariantList SumoInterface::getHexagonColors() const
{
    return hexagonColors;
}

void SumoInterface::findCarsAffectedByFrequency(const QString &referenceVehicleID, const QString message)
{
    // Vider la liste des véhicules à portée au début
    vehiclesInRange.clear();

    qDebug() << referenceVehicleID << "envoie: " << message;

    double signalStrengthCar = -1.0;
    double referenceLat = 0.0;
    double referenceLon = 0.0;

    for (const QVariant &carVariant : vehiclePositions)
    {
        QVariantMap carMap = carVariant.toMap();
        QString currentId = carMap["id"].toString();

        if (currentId == referenceVehicleID)
        {
            signalStrengthCar = carMap["strength"].toDouble();
            referenceLat = carMap["latitude"].toDouble();
            referenceLon = carMap["longitude"].toDouble();
            break; // Sortir de la boucle dès que l'ID est trouvé
        }
    }

    if (signalStrengthCar == -1.0)
    {
        qDebug() << "Vehicule cliqué pas trouvé: " << referenceVehicleID;
        return;
    }
    int index = 0;
    for (const QVariant &voitureVariant : vehiclePositions)
    {
        QVariantMap voitureMap = voitureVariant.toMap();
        QString currentID = voitureMap["id"].toString();

        if (currentID != referenceVehicleID)
        {
            qreal voitureLat = voitureMap["latitude"].toReal();
            qreal voitureLon = voitureMap["longitude"].toReal();

            double distance = distanceBetweenPoints(referenceLat, referenceLon, voitureLat, voitureLon);
            double signalStrength = calculateSignalStrength(distance, signalStrengthCar);

            if (signalStrength >= 10.0)
            {
                vehiclesInRange.insert(currentID, signalStrength);
                voitureMap["message"] = message;
                vehiclePositions[index] = voitureMap;
            }
        }
        index++;
    }
    convertToArray();
}

void SumoInterface::updateVehiclePositions()
{
    QVariantList newPositions;

    // Step the simulation forward
    traci.simulationStep();
    // qDebug() << "Simulation stepped";

    // Get the IDs of all the vehicles
    std::vector<std::string> vehicleIds = traci.vehicle.getIDList();

    // Get the positions of all the vehicles
    for (const std::string &id : vehicleIds)
    {
        double x = traci.vehicle.getPosition(id).x;
        double y = traci.vehicle.getPosition(id).y;
        double heading = traci.vehicle.getAngle(id);
        GeoCoordinates result = GeoConverter::convertGeo(x, y);
        QVariantMap vehicle;
        vehicle["id"] = QString::fromStdString(id);
        vehicle["latitude"] = result.lat;
        vehicle["longitude"] = result.lon;
        vehicle["rotation"] = heading;
        vehicle["strength"] = 20;
        vehicle["message"] = "";

        QColor carColor = applyColor(QString::fromStdString(id)); // Convertit la couleur en QVariant et l'associe à la clé "color" dans le QVariantMap
        QVariant colorVariant = QVariant::fromValue(carColor);
        vehicle["color"] = colorVariant;

        newPositions.append(vehicle);
    }

    // Check if the positions have changed
    if (newPositions != vehiclePositions)
    {
        vehiclePositions = newPositions;
        emit vehiclePositionsChanged();
        emit vehiclePositionsUpdated(newPositions);
    }
}