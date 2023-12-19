#include "headers/SumoInterface.h"
#include <iostream>
#include "geoconverter.h"

SumoInterface::SumoInterface(QObject *parent) : QObject(parent)
{
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

void SumoInterface::changeSpeedCar()
{
}

QVariantList SumoInterface::getVehiclePositions() const
{
    return vehiclePositions;
}

void SumoInterface::updateVehiclePositions()
{
    QVariantList newPositions;

    // Step the simulation forward
    qDebug() << "Stepping the simulation";
    traci.simulationStep();
    qDebug() << "Simulation stepped";

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
        newPositions.append(vehicle);
        qDebug() << "Vehicle ID:" << QString::fromStdString(id)
                 << "Latitude:" << result.lat
                 << "Longitude:" << result.lon;
    }

    // Check if the positions have changed
    if (newPositions != vehiclePositions)
    {
        vehiclePositions = newPositions;
        emit vehiclePositionsChanged();
        emit vehiclePositionsUpdated(newPositions);
    }
}
