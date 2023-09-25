import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.Application.Storage;

(:typecheck(disableBackgroundCheck))
function toPoiData(data as Dictionary) as PoiData {
  try {
    var bgData = data as Dictionary;

    /*
         "lat": 52.15150518174673,
         "lon": 4.774347540760808,
         "set": "202307Drinkwaterkaart",
         "range": 30000,
         // @@ optimize size? xxx,xxx,xxx
         "pts": [
            [52.150449857,4.779379378 ]
                         ..
             ]
     */

    var pts = [] as Array<WayPoint>;

    var lat = ($.getDictionaryValue(bgData, "lat", 0.0d) as Double).toDouble();
    var lon = ($.getDictionaryValue(bgData, "lon", 0.0d) as Double).toDouble();
    var set = ($.getDictionaryValue(bgData, "set", "") as String).toString();
    var range = ($.getDictionaryValue(bgData, "range", 0) as Number).toNumber();

    if (bgData["pts"] != null) {
      // System.println(bgData["pts"]);
      var bg_pts = bgData["pts"] as Array<Array<Double> >;
      for (var i = 0; i < bg_pts.size(); i++) {
        var bg_wpt_latlon = bg_pts[i] as Array<Double>;
        var wpt_lat = bg_wpt_latlon[0]; //($.getDictionaryValue(bg_wpt, "lat", 0.0d) as Double).toDouble();
        var wpt_lon = bg_wpt_latlon[1]; //($.getDictionaryValue(bg_wpt, "lon", 0.0d) as Double).toDouble();
        var wpt = new WayPoint(wpt_lat, wpt_lon);
        pts.add(wpt);
      }

      if ($.gCacheBgData) {
        setCachedBgData(bg_pts);
      }
    }

    return new PoiData(lat, lon, range, set, pts);
  } catch (ex) {
    ex.printStackTrace();
    return new PoiData(0.0d, 0.0d, 0, "Error", [] as Array<WayPoint>);
  }
}
(:typecheck(disableBackgroundCheck))
function getCachedWayPoints() as Array<WayPoint> {
  try {
    var data = Storage.getValue("latest_waypoints");
    if (data == null) {
      return [] as Array<WayPoint>;
    }
    var latest = data as Array<Array<Double> >;
    var waypoints = [] as Array<WayPoint>;
    for (var i = 0; i < latest.size(); i++) {
      var latlon = latest[i] as Array<Double>;
      waypoints.add(new WayPoint(latlon[0], latlon[1]));
    }
    return waypoints;
  } catch (ex) {
    ex.printStackTrace();
  }
  return [] as Array<WayPoint>;
}

(:typecheck(disableBackgroundCheck))
function setCachedBgData(waypoints as Array<Array<Double> >) as Void {
  try {
    Storage.setValue("latest_waypoints", waypoints);
  } catch (ex) {
    ex.printStackTrace();
  }
}
