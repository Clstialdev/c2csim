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
    Q_PROPERTY(QVariantList hexagonColors READ getHexagonColors NOTIFY hexagonColorsChanged)
public:
    explicit SumoInterface(QObject *parent = nullptr);
    ~SumoInterface();

    Q_INVOKABLE void startSimulation();
    Q_INVOKABLE void stopSimulation();
    QVariantList getVehiclePositions() const;
    Q_INVOKABLE void updateVehiclePositions();

    Q_INVOKABLE void changeSpeedCar(const QVariant &vehicleID, double speed);
    Q_INVOKABLE double recupVitesse(const QVariant &vehicleID);
    double calculateSignalStrength(double distance, double signalStrengthAtOneMeter);
    double distanceBetweenPoints(double lat1, double lon1, double lat2, double lon2);
    constexpr double degreesToRadians(double degrees);

    QVariantList getHexagonColors() const;
    Q_INVOKABLE QColor applyColor(const QString &idString);
    Q_INVOKABLE void applyColorToSVG(const QString &id);
    Q_INVOKABLE void addHexagon(const QString &idHex, qreal xCenter, qreal yCenter);
    Q_INVOKABLE bool isPointInsideHexagon(qreal pointX, qreal pointY, qreal hexagonXCenter, qreal hexagonYCenter);

    Q_INVOKABLE void findCarsAffectedByFrequency(const QString &referenceVehicleID);
    Q_INVOKABLE QHash<QString, double> getVehiclesInRange() const { return vehiclesInRange; }

public slots:
    Q_INVOKABLE void updateHexagonColor();

signals:
    void vehiclePositionsChanged();
    void vehiclePositionsUpdated(const QVariantList &newPositions);
    void sendHexagonColor(const QString &hexagonId, const QString &colorName);
    void hexagonColorsChanged();

private:
    TraCIAPI traci;
    QVariantList vehiclePositions;
    QVariantList listHexagons;
    QVariantList hexagonColors;
    QHash<QString, QColor> vehicleColors;
    QHash<QString, double> vehiclesInRange;
};

#endif // SUMOINTERFACE_H