#include "geoconverter.h"
#include <QDebug>

GeoCoordinates GeoConverter::convertGeo(double x, double y)
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

    double lat = qRound((a * x + b * y + c) * 1000000) / 1000000.0;
    double lon = qRound((d * x + e * y + f) * 1000000) / 1000000.0;

    return {lat, lon};
}
