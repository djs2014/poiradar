import Toybox.Activity;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Position;
import Toybox.Weather;
import Toybox.Time;
import Toybox.Application.Storage;

class CurrentLocation {
  hidden var mLat as Lang.Double = 0.0d;
  hidden var mLon as Lang.Double = 0.0d;
  hidden var mLocation as Location?;
  hidden function setLocation(location as Location?) as Void {
    if (location == null) {
      return;
    }
    mLocation = location;
    var degrees = (mLocation as Location).toDegrees();
    var lat = degrees[0];
    var lon = degrees[1];
    if (lat.toNumber() != 0 && lon.toNumber() != 0 && mLat != lat && mLon != lon) {
      Storage.setValue("latest_latlng", degrees); // [lat,lng]
      System.println("Update cached location lat/lon: " + degrees);
    }
    mLat = lat;
    mLon = lon;
  }

  hidden var mAccuracy as Quality? = Position.QUALITY_NOT_AVAILABLE;
  hidden var mSunrise as Moment?;
  hidden var mSunset as Moment?;

  var methodLocationChanged as Method?;
  function setOnLocationChanged(objInstance as Object?, callback as Symbol) as Void {
    methodLocationChanged = new Lang.Method(objInstance, callback);
  }
  function initialize() {}

  function hasLocation() as Boolean {
    if (mLat == 0.0 && mLon == 0.0) {
      var degrees = Storage.getValue("latest_latlng");
      if (degrees != null) {
        mLat = (degrees as Array)[0] as Double;
        mLon = (degrees as Array)[1] as Double;
        mAccuracy = Position.QUALITY_LAST_KNOWN;
        System.println("Using cached location lat/lon: " + [mLat, mLon] + " accuracy: " + mAccuracy);
      }
    }

    if ((mLat == 0.0 || mLat >= 179.99 || mLat <= -179.99) && (mLon == 0.0 || mLon >= 179.99 || mLon <= -179.99)) {
      System.println("Invalid location lat/lon: " + [mLat, mLon] + " accuracy: " + mAccuracy);
      return false;
    }

    return true; //mLat != 0.0 && mLon != 0.0;
  }

  function getCurrentDegrees() as Array<Double> {
    if (!hasLocation()) {
      return [0.0d, 0.0d] as Array<Double>;
    }
    return [mLat, mLon] as Array<Double>;
  }

  function infoLocation() as String {
    if (!hasLocation()) {
      return "No location";
    }
    return mLat.format("%2.4f") + "," + mLon.format("%2.4f");
  }

  function getAccuracy() as Quality {
    if (mAccuracy == null) {
      return Position.QUALITY_NOT_AVAILABLE;
    }
    return mAccuracy as Quality;
  }

  function infoAccuracy() as String {
    if (mAccuracy == null) {
      return "Not available";
    }
    
    switch (mAccuracy as Quality) {
      case 0:
        return "Not available";
      case 1:
        return "Last known";
      case 2:
        return "Poor";
      case 3:
        return "Usable";
      case 4:
        return "Good";
      default:
        return "Not available";
    }
  }

  function onCompute(info as Activity.Info) as Void {
    try {
      var location = null;
      mAccuracy = Position.QUALITY_NOT_AVAILABLE;

      if (info has :currentLocation && info.currentLocation != null) {
        location = info.currentLocation as Location;
        if (info has :currentLocationAccuracy && info.currentLocationAccuracy != null) {
          mAccuracy = info.currentLocationAccuracy;
        }
        if (locationChanged(location)) {
          System.println("Activity location lat/lon: " + location.toDegrees() + " accuracy: " + mAccuracy);
          setSunRiseAndSunSet(location);
          onLocationChanged();
        }
      }

      if (location == null) {
        var posnInfo = Position.getInfo();
        if (posnInfo has :position && posnInfo.position != null) {
          location = posnInfo.position as Location;
          if (posnInfo has :accuracy && posnInfo.accuracy != null) {
            mAccuracy = posnInfo.accuracy;
          }
          if (locationChanged(location)) {
            System.println("Position location lat/lon: " + location.toDegrees() + " accuracy: " + mAccuracy);
            setSunRiseAndSunSet(location);
            onLocationChanged();
          }
        }
      }
      if (location != null && validLocation(location)) {
        setLocation(location);
      } else if (mLocation != null) {
        mAccuracy = Position.QUALITY_LAST_KNOWN;
      }
    } catch (ex) {
      ex.printStackTrace();
    }
  }

  hidden function onLocationChanged() as Void {
    if (methodLocationChanged == null) {
      return;
    }
    (methodLocationChanged as Method).invoke();
  }
  hidden function locationChanged(location as Location?) as Boolean {
    if (location == null) {
      if (mLocation == null) {
        return false;
      } else {
        return true;
      }
    }
    if (mLocation == null) {
      return true;
    }
    // This will crash the compiler when on strict level
    // if (mLocation == null && location == null ){ return false; }
    // if ( (mLocation != null && location == null) || (mLocation == null && location != null) ){ return true; }

    var currentLocation = mLocation as Location;
    var currentDegrees = currentLocation.toDegrees();

    var newLocation = location as Location;
    if (!validLocation(newLocation)) {
      return false;
    }

    var newDegrees = newLocation.toDegrees();
    return newDegrees[0] != currentDegrees[0] && newDegrees[1] != currentDegrees[1];
  }

  hidden function validLocation(location as Location?) as Boolean {
    if (location == null) {
      return false;
    }
    var degrees = (location as Location).toDegrees();

    if ((degrees[0] >= 179.99 || degrees[0] <= -179.99) && (degrees[1] >= 179.99 || degrees[1] <= -179.99)) {
      System.println("Invalid location lat/lon: " + degrees + " accuracy: " + mAccuracy);
      return false;
    }
    return true;
  }

  hidden function setSunRiseAndSunSet(location as Location?) as Void {
    if (location == null) {
      return;
    }
    mSunrise = Weather.getSunrise(location as Location, Time.now()); // ex: 13-6-2022 05:20:43
    mSunset = Weather.getSunset(location as Location, Time.now()); // ex: 13-6-2022 22:02:25
    System.println("Sunrise:" + $.getShortTimeString(mSunrise) + " sunset: " + $.getShortTimeString(mSunset));
  }

  function isAtDaylightTime(time as Moment?, defValue as Boolean) as Boolean {
    if (time == null || mSunrise == null || mSunset == null) {
      return defValue;
    }

    // System.println("Sunrise:" + $.getShortTimeString(mSunrise) + "test: " +  $.getShortTimeString(time) + " sunset: " + $.getShortTimeString(mSunset) );
    return (
      (mSunrise as Moment).value() <= (time as Moment).value() &&
      (time as Moment).value() <= (mSunset as Moment).value()
    );
  }

  function isAtNightTime(time as Moment?, defValue as Boolean) as Boolean {
    // mSunrise < mSunset
    return !isAtDaylightTime(time, !defValue); // ! default value
  }

  function getRelativeToObservation(latObservation as Double, lonObservation as Double) as String {
    if (!hasLocation() || latObservation == 0.0 || lonObservation == 0.0) {
      return "";
    }

    var currentLocation = mLocation as Location;
    var degrees = currentLocation.toDegrees();
    var latCurrent = degrees[0];
    var lonCurrent = degrees[1];

    var distanceMetric = "km";
    var distance = $.getDistanceFromLatLonInKm(latCurrent, lonCurrent, latObservation, lonObservation);

    var deviceSettings = System.getDeviceSettings();
    if (deviceSettings.distanceUnits == System.UNIT_STATUTE) {
      distance = $.kilometerToMile(distance);
      distanceMetric = "m";
    }
    var bearing = $.getRhumbLineBearing(latCurrent, lonCurrent, latObservation, lonObservation);
    var compassDirection = $.getCompassDirection(bearing);

    return format("$1$ $2$ ($3$)", [distance.format("%.2f"), distanceMetric, compassDirection]);
  }
}
