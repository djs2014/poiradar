import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.Application.Storage;

(:typecheck(disableBackgroundCheck))
function toPoiData(data as Dictionary?) as PoiData {
  try {
    if (data == null) {
      return getCachedPoiData();
    }
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
      var bg_pts = bgData["pts"] as Array<Array<Double>>;
      for (var i = 0; i < bg_pts.size(); i++) {
        var bg_wpt_latlon = bg_pts[i] as Array<Double>;
        var wpt_lat = bg_wpt_latlon[0]; //($.getDictionaryValue(bg_wpt, "lat", 0.0d) as Double).toDouble();
        var wpt_lon = bg_wpt_latlon[1]; //($.getDictionaryValue(bg_wpt, "lon", 0.0d) as Double).toDouble();
        var wpt = new WayPoint(wpt_lat, wpt_lon);
        pts.add(wpt);
      }
    }

    return new PoiData(lat, lon, range, set, pts);
  } catch (ex) {
    ex.printStackTrace();
    return getCachedPoiData();
  }
}

(:typecheck(disableBackgroundCheck))
function getCachedPoiData() as PoiData {
  // @@
  // get from storage, if not there, init empty
  //  var data = Storage.getValue("latest_poi");
  //       if (data == null) {
  return new PoiData(0.0d, 0.0d, 0, "", [] as Array<WayPoint>);
  //     }
  // return data as PoiData;

  // var lat as Double = 0.0d;
  // var lon as Double = 0.0d;
  // var range as Number = 0; // meters
  // var set as String = "";
  // var pts as Array<WayPoint> = [] as Array<WayPoint>;
}

// (:typecheck(disableBackgroundCheck))
// function setCachedPoiData(data as PoiData) as Void {
//   // @@
//   // get from storage, if not there, init empty
// }
