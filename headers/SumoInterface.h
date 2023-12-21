#ifndef SUMOINTERFACE_H
#define SUMOINTERFACE_H

#include <QObject>
#include <QVariantList>
#include <QColor>
#include <QVariantMap>
#include <QHash>
// Undefine the signals keyword in Qt
#undef signals

#include "sumo-integrator-master/lib/sumo/TraCIAPI.h"

// Redefine the signals keyword in Qt
#define signals Q_SIGNALS

class SumoInterface : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QVariantList vehiclePositions READ getVehiclePositions NOTIFY vehiclePositionsChanged)
public:
    SumoInterface(QObject *parent = nullptr);
    ~SumoInterface();

    Q_INVOKABLE void startSimulation();
    Q_INVOKABLE void stopSimulation();
    QVariantList getVehiclePositions() const;
    Q_INVOKABLE void changeSpeedCar(const QVariant &vehicleID, double speed);
    Q_INVOKABLE double recupVitesse(const QVariant &vehicleID);
    Q_INVOKABLE QColor applyColor(const QString &idString);
    Q_INVOKABLE void updateVehiclePositions();

signals:
    void vehiclePositionsChanged();
    void vehiclePositionsUpdated(const QVariantList &newPositions);

private:
    TraCIAPI traci;
    QVariantList vehiclePositions;
    QHash<QString, QColor> vehicleColors;
};

#endif // SUMOINTERFACE_H
