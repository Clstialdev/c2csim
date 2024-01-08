#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
// Undefine the signals keyword in Qt
#undef signals

// Include the sumo-integrator headers
#include "sumo-integrator-master/include/sumo-integrator/core/Sumo.h"
#include "sumo-integrator-master/include/sumo-integrator/core/Connection.h"
#include "sumo-integrator-master/include/sumo-integrator/core/Simulation.h"

#include "sumo-integrator-master/lib/sumo/TraCIAPI.h"
#include "sumo-integrator-master/lib/sumo/TraCIConstants.h"
#include "sumo-integrator-master/lib/sumo/TraCIDefs.h"
#include "sumo-integrator-master/lib/sumo/storage.h"

#include "headers/SumoInterface.h"

// Redefine the signals keyword in Qt
#define signals Q_SIGNALS

using namespace std;

struct Point
{
    double x, y, lat, lon;
};

struct GeoCoordinates
{
    double lat, lon;
};

GeoCoordinates convertGeo(double x, double y)
{
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

    QGuiApplication app(argc, argv);
    qmlRegisterType<SumoInterface>("Sumo", 1, 0, "SumoInterface"); ///
    QQmlApplicationEngine engine;

    SumoInterface sumoInterface; /// Create the application core with signals and slots

    QQmlContext *context = engine.rootContext(); ///

    /* We load the object into the context to establish the connection,
     * and also define the name "appCore" by which the connection will occur
     * */
    context->setContextProperty("sumoInterface", &sumoInterface); ///

    const QUrl url(u"qrc:/sumotest/Main.qml"_qs);
    QObject::connect(
        &engine, &QQmlApplicationEngine::objectCreationFailed,
        &app, []()
        { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    engine.load(url);

    return app.exec();
}
