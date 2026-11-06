import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.Application.Storage;

(:typecheck(disableBackgroundCheck))
function overpassToPoiData(data as Dictionary) as PoiData {
  try {
    var bgData = data as Dictionary;

    /*
      Direct Overpass API response, e.g.:
      {
        "elements": [
          { "type": "node", "id": 442958957, "lat": 52.3548191, "lon": 4.8986173, "tags": {...} },
          { "type": "way", "id": 123, "center": { "lat": 52.3, "lon": 4.8 }, "tags": {...} }
        ]
      }
      Nodes carry lat/lon directly, ways/relations carry them in center
      (query uses "out tags center").
    */

    var pts = [] as Array<WayPoint>;

    // Overpass echoes no request origin, reuse the cached fix instead.
    var originLat = 0.0d;
    var originLon = 0.0d;
    var cached = Storage.getValue("latest_latlng");
    if (cached instanceof Array && (cached as Array).size() >= 2) {
      var cachedLatLon = cached as Array;
      originLat = overpassCoord(cachedLatLon[0]);
      originLon = overpassCoord(cachedLatLon[1]);
    }
    var maxRange = 30000;
    var storedRange = Storage.getValue("maxRangeMeters");
    if (storedRange instanceof Number) {
      maxRange = storedRange as Number;
    }
    var maxWpts = 50;
    var storedWpts = Storage.getValue("maxWaypoints");
    if (storedWpts instanceof Number) {
      maxWpts = storedWpts as Number;
    }

    var elements = bgData["elements"];
    if (elements instanceof Array) {
      var list = elements as Array;
      for (var i = 0; i < list.size() && pts.size() < maxWpts; i++) {
        if (!(list[i] instanceof Dictionary)) {
          continue;
        }
        var el = list[i] as Dictionary;

        var wptLat = overpassCoord(el["lat"]);
        var wptLon = overpassCoord(el["lon"]);
        if (wptLat == 0.0d && wptLon == 0.0d) {
          // ways/relations expose coordinates via center (out tags center)
          var center = el["center"];
          if (center instanceof Dictionary) {
            wptLat = overpassCoord((center as Dictionary)["lat"]);
            wptLon = overpassCoord((center as Dictionary)["lon"]);
          }
        }
        if (wptLat == 0.0d && wptLon == 0.0d) {
          continue;
        }
        if (originLat != 0.0d || originLon != 0.0d) {
          var distMeters = $.getDistanceFromLatLonInKm(originLat, originLon, wptLat, wptLon) * 1000;
          if (distMeters > maxRange) {
            continue;
          }
        }

        var tags = el["tags"];
        if (!(tags instanceof Dictionary)) {
          tags = {} as Dictionary;
        }
        var wpt = new WayPoint(wptLat, wptLon);
        wpt.code = overpassCode(tags as Dictionary);
        wpt.available = overpassAvailable(tags as Dictionary);
        pts.add(wpt);
      }
    }

    return new PoiData(originLat, originLon, maxRange, "OSM Toilets & Drinking Water", 1, pts);
  } catch (ex) {
    ex.printStackTrace();
    return new PoiData(0.0d, 0.0d, 0, "Error", 0, [] as Array<WayPoint>);
  }
}

// JSON numbers may decode as Number/Long/Float/Double (or String),
// normalize defensively; 0.0d means "no usable coordinate".
function overpassCoord(value as Object?) as Double {
  if (value instanceof Number) {
    return (value as Number).toDouble();
  }
  if (value instanceof Float) {
    return (value as Float).toDouble();
  }
  if (value instanceof Double) {
    return value as Double;
  }
  if (value instanceof Long) {
    return (value as Long).toDouble();
  }
  if (value instanceof String) {
    return (value as String).toDouble();
  }
  return 0.0d;
}

// Mirrors server osmutil.js extractCode: -1 not drinkable, 0 neutral,
// 1 drinking water, 2 toilet, 3 toilet + drinking water.
function overpassCode(tags as Dictionary) as Number {
  var amenity = tags["amenity"];
  var drinkingWater = tags["drinking_water"];
  if (amenity != null && amenity.equals("drinking_water")) {
    if (drinkingWater != null && drinkingWater.equals("no")) {
      return -1;
    }
    return 1;
  }
  if (amenity != null && amenity.equals("toilets")) {
    if (drinkingWater != null && drinkingWater.equals("yes")) {
      return 3;
    }
    return 2;
  }
  if (drinkingWater != null && drinkingWater.equals("no")) {
    return -1;
  }
  return 0;
}

// Lightweight availability check (server evaluates opening_hours etc.,
// too heavy for the device): only clear closed/inaccessible signals.
function overpassAvailable(tags as Dictionary) as Boolean {
  var access = tags["access"];
  if (access != null && (access.equals("no") || access.equals("private"))) {
    return false;
  }
  var operationalStatus = tags["operational_status"];
  if (operationalStatus != null && (operationalStatus.equals("closed") || operationalStatus.equals("out_of_order"))) {
    return false;
  }
  var drinkingWater = tags["drinking_water"];
  if (drinkingWater != null && drinkingWater.equals("no")) {
    return false;
  }
  return true;
}
