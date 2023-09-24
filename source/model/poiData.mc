import Toybox.Lang;
import Toybox.Math;

class PoiData {
  public var lat as Double = 0.0d;
  public var lon as Double = 0.0d;
  public var range as Number = 0; // meters
  public var set as String = "";
  public var pts as Array<WayPoint> = [] as Array<WayPoint>;

  function initialize(lat as Double, lon as Double, range as Number, set as String, pts as Array<WayPoint>) {
    self.lat = lat;
    self.lon = lon;
    self.range = range;
    self.set = set;
    self.pts = pts;
  }

  function toString() as String {
    return "lat[" + lat + "]lon[" + lon + "]range[" + range + "]set[" + set + "]#pts[" + pts.size() + "]";
  }
}

class WayPoint {
  var lat as Lang.Double = 0d;
  var lon as Lang.Double = 0d;
  // @@ TODO
  var name as Lang.String = "";
  var comment as Lang.String = "";
  function initialize(lat as Double or Float, lon as Double or Float) {
    self.lat = lat.toDouble();
    self.lon = lon.toDouble();
  }
}

function getWayPointByDistanceAndHeading(
  lat as Double,
  lon as Double,
  heading as Double,
  distanceKm as Double
) as WayPoint {
  var EarthRadius = 6378.1d;
  var bearingR = $.deg2rad(heading);
  var latR = $.deg2rad(lat);
  var lonR = $.deg2rad(lon);

  var distanceToRadius = distanceKm / EarthRadius;

  var newLatR = Math.asin(
    Math.sin(latR) * Math.cos(distanceToRadius) + Math.cos(latR) * Math.sin(distanceToRadius) * Math.cos(bearingR)
  );

  var newLonR =
    lonR +
    Math.atan2(
      Math.sin(bearingR) * Math.sin(distanceToRadius) * Math.cos(latR),
      Math.cos(distanceToRadius) - Math.sin(latR) * Math.sin(newLatR)
    );

  return new WayPoint($.rad2deg(newLatR), $.rad2deg(newLonR));
}
