import Toybox.System;
import Toybox.Math;
import Toybox.Lang;

function getDistanceFromLatLonInKm(
  latFrom as Numeric,
  lonFrom as Numeric,
  latTo as Numeric,
  lonTo as Numeric
) as Float {
  if (latFrom == null || lonFrom == null || latTo == null || lonTo == null) {
    return 0.0f;
  }

  var R = 6371; // Radius of the earth in km
  var dLat = deg2rad(latTo - latFrom); // deg2rad below
  var dLon = deg2rad(lonTo - lonFrom);
  var a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(deg2rad(latFrom)) * Math.cos(deg2rad(latTo)) * Math.sin(dLon / 2) * Math.sin(dLon / 2);
  var c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  var d = R * c; // Distance in km
  return d as Float;
}

function deg2rad(deg as Numeric) as Double or Float {
  return deg * (Math.PI / 180);
}

function rad2deg(rad as Numeric?) as Double or Float {
  if (rad == null) {
    return 0.0;
  }
  var deg = (rad * 180) / Math.PI;
  if (deg < 0) {
    deg += 360.0;
  }
  return deg;
}

// http://www.dougv.com/2009/07/13/calculating-the-bearing-and-compass-rose-direction-between-two-latitude-longitude-coordinates-in-php/
function getRhumbLineBearing(latFrom as Numeric, lonFrom as Numeric, latTo as Numeric, lonTo as Numeric) as Number {
  if (latFrom == null || lonFrom == null || latTo == null || lonTo == null) {
    return 0;
  }

  // difference in longitudinal coordinates
  var dLon = deg2rad(lonTo) - deg2rad(lonFrom);
  // difference in the phi of latitudinal coordinates
  var dPhi = Math.log(
    Math.tan(deg2rad(latTo) / 2 + Math.PI / 4) / Math.tan(deg2rad(latFrom) / 2 + Math.PI / 4),
    Math.E
  );

  // we need to recalculate dLon if it is greater than pi
  if (dLon.abs() > Math.PI) {
    if (dLon > 0) {
      dLon = (2 * Math.PI - dLon) * -1;
    } else {
      dLon = 2 * Math.PI + dLon;
    }
  }
  // return the angle, normalized
  // not allowed to `modulo` double values, truncate the value to integer
  // value
  return (rad2deg(Math.atan2(dLon, dPhi)) + 360).toNumber() % 360;
}

// bearing in degrees
function getCompassDirection(bearing as Numeric) as String {
  var direction = "";
  // Round and convert to number (1.00000 -> 1)
  switch (Math.round(bearing / 22.5).toNumber()) {
    case 1:
      direction = "NNE";
      break;
    case 2:
      direction = "NE";
      break;
    case 3:
      direction = "ENE";
      break;
    case 4:
      direction = "E";
      break;
    case 5:
      direction = "ESE";
      break;
    case 6:
      direction = "SE";
      break;
    case 7:
      direction = "SSE";
      break;
    case 8:
      direction = "S";
      break;
    case 9:
      direction = "SSW";
      break;
    case 10:
      direction = "SW";
      break;
    case 11:
      direction = "WSW";
      break;
    case 12:
      direction = "W";
      break;
    case 13:
      direction = "WNW";
      break;
    case 14:
      direction = "NW";
      break;
    case 15:
      direction = "NNW";
      break;
    default:
      direction = "N";
  }

  return direction;
}
// https://www.mathsisfun.com/algebra/trigonometry.html
// trigononmetry degrees  0 is right, 90 is top, 180 is left, 270 is bottom
// bearing degrees 0 is North, 90 is East, 180 is South, 270 is West
function getPointOnCircle(x as Number, y as Number, angleInDegrees as Number, radius as Numeric) as Point {
  // Convert from degrees to radians
  angleInDegrees = angleInDegrees % 360;
  var px = x + radius * Math.cos((angleInDegrees * Math.PI) / 180);
  var py = y - radius * Math.sin((angleInDegrees * Math.PI) / 180);

  return new Point(px.toNumber(), py.toNumber());
}

function getBearingPointOnCircle(x as Number, y as Number, bearingInDegrees as Number, radius as Numeric) as Point {
  // convert to trigonometry
  bearingInDegrees = bearingInDegrees + 90;
  // Convert from degrees to radians
  bearingInDegrees = bearingInDegrees % 360;
  // swap x
  var px = x - radius * Math.cos((bearingInDegrees * Math.PI) / 180);
  var py = y - radius * Math.sin((bearingInDegrees * Math.PI) / 180);

  return new Point(px.toNumber(), py.toNumber());
}
function convertGeoToPixel(
  latitude as Double,
  longitude as Double,
  mapWidth as Number, // in pixels
  mapHeight as Number, // in pixels
  mapLngLeft as Double, // in degrees. the longitude of the left side of
  // the map (i.e. the longitude of whatever is
  // depicted on the left-most part of the map image)
  mapLngRight as Double, // in degrees. the longitude of the right side of the map
  mapLatBottom as Double // in degrees.  the latitude of the bottom of the map
) as Point {
  var mapLatBottomRad = (mapLatBottom * Math.PI) / 180;
  var latitudeRad = (latitude * Math.PI) / 180;
  var mapLngDelta = mapLngRight - mapLngLeft;
  if (mapLngDelta == 0l) {
    return new Point(0,0);
  }
  var worldMapWidth = ((mapWidth / mapLngDelta) * 360) / (2 * Math.PI);
  var mapOffsetY =
    (worldMapWidth / 2) * Math.log((1 + Math.sin(mapLatBottomRad)) / (1 - Math.sin(mapLatBottomRad)), Math.E);

  var x = (longitude - mapLngLeft) * (mapWidth / mapLngDelta);
  var y =
    mapHeight -
    ((worldMapWidth / 2) * Math.log((1 + Math.sin(latitudeRad)) / (1 - Math.sin(latitudeRad)), Math.E) - mapOffsetY);

  return new Point(x.toNumber(), y.toNumber()); // the pixel x,y value of this point on the map image
}
