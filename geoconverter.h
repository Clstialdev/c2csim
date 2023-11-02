#ifndef GEOCONVERTER_H
#define GEOCONVERTER_H

struct Point {
    double x, y, lat, lon;
};

struct GeoCoordinates {
    double lat, lon;
};

class GeoConverter {
public:
    static GeoCoordinates convertGeo(double x, double y);
};

#endif // GEOCONVERTER_H
