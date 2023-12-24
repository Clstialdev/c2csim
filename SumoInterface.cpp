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

#include "geoconverter.h"

bool first_init = true;

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

void SumoInterface::applyColorToSVG(const QString &id)
{
    qDebug() << "Entrée dans applyColortoSVG";
    QColor carColor = applyColor(id); //.value<QColor>();
    qDebug() << "Conversion en QColor réussie";

    // Charger le fichier SVG
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
    QString colorString = carColor.name(); // Obtenir le nom de la couleur (par exemple, "#RRGGBB")
    svgContent.replace("fill=\"#000000\"", "fill=\"" + colorString + "\"");

    // Générer un nom de fichier unique en utilisant l'ID de la voiture
    QString uniqueFileName = QCoreApplication::applicationDirPath() + "/images/generated/car_modified_" + id + ".svg";

    // Sauvegarder le fichier SVG modifié avec un nom de fichier unique
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

/*
void SumoInterface::applyColorToSVG(const QString &id, const QString &colorString)
{
    qDebug() << "Entrée dans applyColortoSVG";
    // QColor carColor = colorVariant; //.value<QColor>();
    qDebug() << "Conversion en QColor réussie";

    // Charger le fichier SVG
    QFile file("images/car-cropped.svg");
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text))
    {
        qDebug() << "Erreur lors de l'ouverture du fichier SVG";
        return;
    }

    QTextStream in(&file);
    QString svgContent = in.readAll();
    file.close();

    // Modifier la couleur dans le fichier SVG
    // QString colorString = carColor.name(); // Obtenir le nom de la couleur (par exemple, "#RRGGBB")
    svgContent.replace("fill=\"#000000\"", "fill=\"" + colorString + "\"");

    // Générer un nom de fichier unique en utilisant l'ID de la voiture
    QString uniqueFileName = "images/generated/car_modified_" + id + ".svg";

    // Sauvegarder le fichier SVG modifié avec un nom de fichier unique
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

*/

double SumoInterface::recupVitesse(const QVariant &vehicleID)
{
    QString idString = vehicleID.toString();
    // qDebug() << "Current Speed:" << traci.vehicle.getSpeed(idString.toStdString());

    return traci.vehicle.getSpeed(idString.toStdString());
}

QVariantList SumoInterface::getVehiclePositions() const
{
    return vehiclePositions;
}
void SumoInterface::updateHexagonColor()
{
}

void SumoInterface::updateVehiclePositions()
{
    QVariantList newPositions;

    // Step the simulation forward
    // qDebug() << "Stepping the simulation";
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

        QColor carColor = applyColor(QString::fromStdString(id)); // Convertit la couleur en QVariant et l'associe à la clé "color" dans le QVariantMap
        QVariant colorVariant = QVariant::fromValue(carColor);
        vehicle["color"] = colorVariant;

        newPositions.append(vehicle);

        /*
        qDebug() << "Vehicle ID:" << QString::fromStdString(id)
                 << "Color:" << carColor
                 << "Color Variant:" << colorVariant;

        qDebug() << "Vehicle ID:" << QString::fromStdString(id)
                 << "Latitude:" << result.lat
                 << "Longitude:" << result.lon;

                 */
    }
    first_init = false;

    // Check if the positions have changed
    if (newPositions != vehiclePositions)
    {
        vehiclePositions = newPositions;
        emit vehiclePositionsChanged();
        emit vehiclePositionsUpdated(newPositions);
    }
}
