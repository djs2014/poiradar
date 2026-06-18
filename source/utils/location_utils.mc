// 2024-05-26 setLocation lat/lon toDouble
// 2025-11-10 location changed fix
// 2025-11-11 do not cache sunrise/set
// 2026-06-01 added debug mode to slope calc and location
// 2026-06-02 callback weak reference fix
import Toybox.Activity;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Position;
import Toybox.Weather;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.Application.Storage;

class CurrentLocation {
  hidden var debugMode = false;
  function setDebugMode(enabled as Boolean) as Void {
    debugMode = enabled;
  }
  hidden var mLat as Lang.Double = 0.0d;
  hidden var mLon as Lang.Double = 0.0d;
  hidden var mLocation as Location?;
  hidden var mStorageLatestLocation as String = "latest_latlng";

  hidden var mPreviousLat as Lang.Double = 0.0d;
  hidden var mPreviousLon as Lang.Double = 0.0d;
  hidden var mMinDegreesDifferenceSunevent as Lang.Double = 1.0d;

  hidden function setLocation(location as Location?) as Void {
    if (location == null) {
      return;
    }
    mLocation = location;
    var degrees = (mLocation as Location).toDegrees();
    if (degrees.size() < 2) {
      return;
    }
    var lat = degrees[0].toDouble();
    var lon = degrees[1].toDouble();
    if (lat == null || lon == null) {
      return;
    }
    if (lat != 0 && lon != 0 && mLat != lat && mLon != lon) {
      Storage.setValue(mStorageLatestLocation, degrees); // [lat,lng]
      if (debugMode) {
        System.println("Update cached location lat/lon: " + degrees);
      }
    }
    mLat = lat;
    mLon = lon;
  }

  hidden var mAccuracy as Quality? = Position.QUALITY_NOT_AVAILABLE;

  hidden var mCbLocationChangedTargetRef as WeakReference?;
  hidden var mCbLocationChangedMethodName as Symbol?;
  function setOnLocationChanged(target as Object, callback as Symbol) as Void {
    mCbLocationChangedTargetRef = target.weak();
    mCbLocationChangedMethodName = callback;
  }

  // Sunrise sunset changed: triggers when latitude changes 1 degree
  hidden var mCbSunEventChangedTargetRef as WeakReference?;
  hidden var mCbSunEventChangedMethodName as Symbol?;
  function setOnSunEventChanged(
    objInstance as Object,
    callback as Symbol
  ) as Void {
    mCbSunEventChangedTargetRef = objInstance.weak();
    mCbSunEventChangedMethodName = callback;
  }
  // Minimal difference in lat or lon that will trigger new calculation of sunrise/sunset
  function setMinDegreesDifferenceSunevent(
    minDifference as Lang.Double
  ) as Void {
    mMinDegreesDifferenceSunevent = minDifference;
  }

  function initialize() {}

  function hasLocation() as Boolean {
    if (
      (mLat == 0.0 || mLat >= 179.99 || mLat <= -179.99) &&
      (mLon == 0.0 || mLon >= 179.99 || mLon <= -179.99)
    ) {
      var degrees = Storage.getValue(mStorageLatestLocation);
      if (degrees != null) {
        mLat = (degrees as Array)[0] as Double;
        mLon = (degrees as Array)[1] as Double;
        mAccuracy = Position.QUALITY_LAST_KNOWN;
        if (debugMode) {
          System.println(
            "Using cached location lat/lon: " +
              [mLat, mLon] +
              " accuracy: " +
              mAccuracy
          );
        }
      }
    }

    if (
      (mLat == 0.0 || mLat >= 179.99 || mLat <= -179.99) &&
      (mLon == 0.0 || mLon >= 179.99 || mLon <= -179.99)
    ) {
      //System.println("Invalid location lat/lon: " + [mLat, mLon] + " accuracy: " + mAccuracy);
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
      var changed = false;

      var location = null;
      mAccuracy = Position.QUALITY_NOT_AVAILABLE;

      if (info has :currentLocation && info.currentLocation != null) {
        location = info.currentLocation as Location;
        if (
          info has :currentLocationAccuracy &&
          info.currentLocationAccuracy != null
        ) {
          mAccuracy = info.currentLocationAccuracy;
        }
        if (locationChanged(location)) {
          if (debugMode) {
            System.println(
              "Activity location lat/lon: " +
                location.toDegrees() +
                " accuracy: " +
                mAccuracy
            );
          }
          onLocationChanged();
          changed = true;
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
            if (debugMode) {
              System.println(
                "Position location lat/lon: " +
                  location.toDegrees() +
                  " accuracy: " +
                  mAccuracy
              );
            }
            onLocationChanged();
            changed = true;
          }
        }
      }
      if (location != null && validLocation(location)) {
        setLocation(location);
        if (changed && sunSetAndRiseChanged(location)) {
          onSunEventChanged();
        }
      } else if (mLocation != null) {
        mAccuracy = Position.QUALITY_LAST_KNOWN;
      }
    } catch (ex) {
      ex.printStackTrace();
    }
  }

  hidden function onLocationChanged() as Void {
    if (mCbLocationChangedMethodName == null) {
      return;
    }

    if (
      mCbLocationChangedTargetRef != null &&
      mCbLocationChangedTargetRef.stillAlive()
    ) {
      var target = mCbLocationChangedTargetRef.get();

      if (target != null) {
        var callback = target.method(mCbLocationChangedMethodName);

        callback.invoke(getCurrentDegrees() as Array<Double>);
      }
    }
  }

  hidden function onSunEventChanged() as Void {
    if (mCbSunEventChangedMethodName == null || !validLocation(mLocation)) {
      return;
    }

    var time = Time.now();
    var sunrise = Weather.getSunrise(mLocation as Location, time);
    var sunset = Weather.getSunset(mLocation as Location, time);

    if (sunrise != null && sunset != null) {
      if ((sunset as Moment).value() < (sunrise as Moment).value()) {
        // We need the sunset after sunrise, so we got a daytime period from sunrise - to sunset
        if (debugMode) {
          System.println(
            "Sunset is before sunrise, adjusting sunset to next day."
          );
        }
        var oneDay = new Time.Duration(Gregorian.SECONDS_PER_DAY);
        sunset = Weather.getSunset(mLocation as Location, time.add(oneDay));
      }

      if (debugMode) {
        System.println([
          "onSunEventChanged",
          "sunrise:",
          $.getLongTimeString(sunrise),
          "sunset:",
          $.getLongTimeString(sunset),
        ]);
      }
    }

    if (
      mCbSunEventChangedTargetRef != null &&
      mCbSunEventChangedTargetRef.stillAlive()
    ) {
      var target = mCbSunEventChangedTargetRef.get();

      if (target != null) {
        var callback = target.method(mCbSunEventChangedMethodName);

        callback.invoke(sunrise, sunset);
      }
    }
  }

  hidden function locationChanged(location as Location?) as Boolean {
    // Ignore invalid locations
    if (location == null) {
      return false;
    }

    var newLocation = location as Location;
    if (!validLocation(newLocation)) {
      // System.println(["New location is invalid", newLocation.toDegrees()]);
      return false;
    }

    // This will crash the compiler when on strict level
    // if (mLocation == null && location == null ){ return false; }
    // if ( (mLocation != null && location == null) || (mLocation == null && location != null) ){ return true; }

    // No current location, so new is better.
    if (mLocation == null) {
      return true;
    }
    var currentLocation = mLocation as Location;
    var currentDegrees = currentLocation.toDegrees();

    // Position location lat/lon: [49.114117, 3.293631] accuracy: 1
    // TODO: check only to x decimals. Option.
    var newDegrees = newLocation.toDegrees();
    var changed =
      newDegrees[0] != currentDegrees[0] || newDegrees[1] != currentDegrees[1];

    //System.println(["locationChanged", changed, currentDegrees, "->", newDegrees]);
    return changed;
  }

  hidden function sunSetAndRiseChanged(location as Location) as Boolean {
    var degrees = location.toDegrees();
    var lat = degrees[0];
    var lon = degrees[1];

    var changed =
      (mPreviousLat - lat).abs() > mMinDegreesDifferenceSunevent ||
      (mPreviousLon - lon).abs() > mMinDegreesDifferenceSunevent;

    if (debugMode) {
      System.println(
        "Checking sun event change. Previous lat/lon: " +
          [mPreviousLat, mPreviousLon] +
          " New lat/lon: " +
          [lat, lon] +
          " Changed: " +
          changed
      );
    }

    mPreviousLat = lat;
    mPreviousLon = lon;
    return changed;
  }

  hidden function validLocation(location as Location?) as Boolean {
    if (location == null) {
      return false;
    }
    var degrees = (location as Location).toDegrees();

    if (
      (degrees[0] >= 179.99 || degrees[0] <= -179.99) &&
      (degrees[1] >= 179.99 || degrees[1] <= -179.99)
    ) {
      if (debugMode) {
        System.println(
          "Invalid location lat/lon: " + degrees + " accuracy: " + mAccuracy
        );
      }
      return false;
    }
    return true;
  }

  function isAtDaylightTime(time as Moment?, defValue as Boolean) as Boolean {
    if (!validLocation(mLocation)) {
      return defValue;
    }

    if (time == null) {
      return defValue;
    }

    // Note: is sunrise of current day (from time parameter).
    var sunrise = Weather.getSunrise(mLocation as Location, time); // ex: 13-6-2022 05:20:43
    var sunset = Weather.getSunset(mLocation as Location, time); // ex: 13-6-2022 22:02:25

    if ((sunset as Moment).value() < (sunrise as Moment).value()) {
      // We need the sunset after sunrise, so we got a daytime period from sunrise - to sunset
      if (debugMode) {
        System.println(["Get sunrise next day!"]);
      }
      var oneDay = new Time.Duration(Gregorian.SECONDS_PER_DAY);
      sunset = Weather.getSunset(mLocation as Location, time.add(oneDay));
    }

    var dayLightTime =
      (sunrise as Moment).value() <= (time as Moment).value() &&
      (time as Moment).value() <= (sunset as Moment).value();
    // System.println([
    //   "IsDayLight:",
    //   dayLightTime.toString(),
    //   "Sunrise:",
    //   $.getLongTimeString(sunrise),
    //   " sunset:",
    //   $.getLongTimeString(sunset),
    //   " when:",
    //   $.getLongTimeString(time),
    // ]);

    return dayLightTime;
  }

  function isAtNightTime(time as Moment?, defValue as Boolean) as Boolean {
    if (!validLocation(mLocation)) {
      return defValue;
    }

    if (time == null) {
      return defValue;
    }

    // Note: is sunrise of current day (from time parameter).
    var sunrise = Weather.getSunrise(mLocation as Location, time); // ex: 13-6-2022 05:20:43
    var sunset = Weather.getSunset(mLocation as Location, time); // ex: 13-6-2022 22:02:25

    // [IsAtNight:, true, Sunrise:, 13-11-2025 13:57,  sunset:, 13-11-2025 00:08,  when:, 13-11-2025 20:20]
    // Bug? If sunset is before sunrise -> add 1 day to sunset.
    if ((sunset as Moment).value() < (sunrise as Moment).value()) {
      // We need the sunset after sunrise, so we got a daytime period from sunrise - to sunset
      if (debugMode) {
        System.println(["Get sunrise next day!"]);
      }
      var oneDay = new Time.Duration(Gregorian.SECONDS_PER_DAY);
      sunset = Weather.getSunset(mLocation as Location, time.add(oneDay));
    }

    var nightTime =
      (time as Moment).value() < (sunrise as Moment).value() ||
      (sunset as Moment).value() <= (time as Moment).value();

    // System.println([
    //   "IsAtNight:",
    //   nightTime.toString(),
    //   "Sunrise:",
    //   $.getLongTimeString(sunrise),
    //   " sunset:",
    //   $.getLongTimeString(sunset),
    //   " when:",
    //   $.getLongTimeString(time),
    // ]);

    return nightTime;
  }

  // Note: is sunrise of current day. So will return date before now() if the sun has rised already.
  function getSunrise() as Moment? {
    if (!validLocation(mLocation)) {
      return null;
    }
    return Weather.getSunrise(mLocation as Location, Time.now());
  }
  // Note: is sunrise of current day. So will return date before now() if the sun has rised already.
  function getSunset() as Moment? {
    if (!validLocation(mLocation)) {
      return null;
    }
    return Weather.getSunset(mLocation as Location, Time.now());
  }

  function getSunriseTomorrow() as Moment? {
    if (!validLocation(mLocation)) {
      return null;
    }
    var today = new Time.Moment(Time.today().value());
    var oneDay = new Time.Duration(Gregorian.SECONDS_PER_DAY);
    var tomorrow = today.add(oneDay);
    return Weather.getSunrise(mLocation as Location, tomorrow); // ex: 14-6-2022 05:20:43
  }
  function getSunsetTomorrow() as Moment? {
    if (!validLocation(mLocation)) {
      return null;
    }
    var today = new Time.Moment(Time.today().value());
    var oneDay = new Time.Duration(Gregorian.SECONDS_PER_DAY);
    var tomorrow = today.add(oneDay);
    return Weather.getSunset(mLocation as Location, tomorrow); // ex: 14-6-2022 05:20:43
  }

  function getRelativeToObservation(
    latObservation as Double,
    lonObservation as Double
  ) as String {
    if (!hasLocation() || latObservation == 0.0 || lonObservation == 0.0) {
      return "";
    }

    var currentLocation = mLocation as Location;
    var degrees = currentLocation.toDegrees();
    var latCurrent = degrees[0];
    var lonCurrent = degrees[1];

    var distanceMetric = "km";
    var distance = $.getDistanceFromLatLonInKm(
      latCurrent,
      lonCurrent,
      latObservation,
      lonObservation
    );

    var deviceSettings = System.getDeviceSettings();
    if (deviceSettings.distanceUnits == System.UNIT_STATUTE) {
      distance = $.kilometerToMile(distance);
      distanceMetric = "m";
    }
    var bearing = $.getRhumbLineBearing(
      latCurrent,
      lonCurrent,
      latObservation,
      lonObservation
    );
    var compassDirection = $.getCompassDirection(bearing);

    return format("$1$ $2$ ($3$)", [
      distance.format("%.2f"),
      distanceMetric,
      compassDirection,
    ]);
  }
}
