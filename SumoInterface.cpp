#include "headers/SumoInterface.h"
#include <iostream>
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

        /*
        if (first_init == true)
        {
            qDebug() << "dans la boucle init avec first_init= " << first_init;
            // Vérifie si "arret" existe déjà
            if (!vehicle.contains("arret") || vehicle["arret"].isNull())
            {
                vehicle["arret"] = false; // Si "arret" n'existe pas ou est null, attribuez-lui la valeur false
            }

            // Vérifie si "original_speed" existe déjà et n'est pas défini
            if (!vehicle.contains("original_speed") || vehicle["original_speed"].isNull())
            {
                vehicle["original_speed"] = -1.0; // Si "original_speed" n'existe pas ou est null, attribuez-lui la valeur -1.0
            }
        }
        */
        newPositions.append(vehicle);
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
