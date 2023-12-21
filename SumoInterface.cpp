#include "headers/SumoInterface.h"
#include <iostream>
#include <string>
#include <QObject>
#include <QDebug>
#include <QColor>
#include <QRandomGenerator>

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

        /*
        libsumo::TraCIColor traciColor(
            randomColor.red(),
            randomColor.green(),
            randomColor.blue(),
            randomColor.alpha());

        */
        //        traci.vehicle.setColor(idString.toStdString(), traciColor);
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

        qDebug() << "Vehicle ID:" << QString::fromStdString(id)
                 << "Color:" << carColor
                 << "Color Variant:" << colorVariant;
        /*
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
