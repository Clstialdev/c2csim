#include <QGuiApplication>
#include <QQmlApplicationEngine>
// Undefine the signals keyword in Qt
#undef signals

// Include the sumo-integrator headers
#include "sumo-integrator/core/Sumo.h"
#include "sumo-integrator/core/Connection.h"
#include "sumo-integrator/core/Simulation.h"

#include "lib/sumo/TraCIAPI.h"
#include "lib/sumo/TraCIConstants.h"
#include "lib/sumo/TraCIDefs.h"
#include "lib/sumo/storage.h"


#include "headers/SumoInterface.h"

// Redefine the signals keyword in Qt
#define signals Q_SIGNALS


using namespace std;

struct Point {
    double x, y, lat, lon;
};

struct GeoCoordinates {
    double lat, lon;
};

GeoCoordinates convertGeo(double x, double y) {
    // Given points
    Point p1 = {0, 0, 47.734738, 7.308797};
    Point p2 = {5000, 3000, 47.762685, 7.374628};
    Point p3 = {0, 3000, 47.761718, 7.307922};
    Point p4 = {5000, 0, 47.735700, 7.375457};

    // Solving for a, b, d, and e using the given points
    double a = (p4.lat - p1.lat) / (p4.x - p1.x);
    double b = (p3.lat - p1.lat) / (p3.y - p1.y);
    double d = (p4.lon - p1.lon) / (p4.x - p1.x);
    double e = (p3.lon - p1.lon) / (p3.y - p1.y);

    // c and f are the lat and long of the origin
    double c = p1.lat;
    double f = p1.lon;

    // Calculating lat and long for the given x and y
    double lat = a * x + b * y + c;
    double lon = d * x + e * y + f;

    return {lat, lon};
}


int main(int argc, char *argv[])
{

//    // Create an instance of the TraCIAPI class
//    TraCIAPI traci;

//    // Use the methods provided by the TraCIAPI class to interact with SUMO
//    traci.connect("localhost", 6066);
//    // Step into the simulation
//    // Step into the simulation
//    while (true) {
//        // Get the IDs of all the vehicles
//        vector<string> vehicleIds = traci.vehicle.getIDList();

//        // Print the IDs, X and Y positions of all the vehicles
//        for (const string& id : vehicleIds) {
//            double x = traci.vehicle.getPosition(id).x;
//            double y = traci.vehicle.getPosition(id).y;
//            double latitude, longitude;
//            GeoCoordinates result = convertGeo(x, y);
//            latitude = result.lat;
//            longitude = result.lon;
//            // Convert Cartesian coordinates to latitude and longitude
//            cout << "Vehicle ID: " << id << ", X: " << latitude << ", Y: " << longitude << endl;
//        }

//        // Step the simulation forward
//        traci.simulationStep();


//    }


    QGuiApplication app(argc, argv);
    qmlRegisterType<SumoInterface>("Sumo", 1, 0, "SumoInterface");
    QQmlApplicationEngine engine;
    const QUrl url(u"qrc:/sumotest/Main.qml"_qs);
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed,
        &app, []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    engine.load(url);

    return app.exec();
}
