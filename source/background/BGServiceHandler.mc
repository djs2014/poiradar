// Version 1.0.2
import Toybox.Application;
import Toybox.Lang;
import Toybox.System;
import Toybox.Activity;
import Toybox.Position;
import Toybox.Time;
import Toybox.Background;

// using CommunicationsHelpers as Helpers;
import Toybox.Application.Storage;

class BGServiceHandler {
  const HTTP_OK as Number = 200;
  var mCurrentLocation as CurrentLocation?;
  var mError as Number = 0;
  var mHttpStatus as Number = HTTP_OK;
  var mPhoneConnected as Boolean = false;
  var mBGActive as Boolean = false;
  var mBGDisabled as Boolean = false;
  var mErrorMessage as String = "";

  var mUpdateFrequencyInMinutes as Number = 5;
  var mRequestCounter as Number = 0;
  var mObservationTimeDelayedMinutesThreshold as Number = 10;
  var mMinimalGPSLevel as Number = 3;

  var mLastRequestMoment as Time.Moment?;
  var mLastObservationMoment as Time.Moment?;
  var mCacheBgData as Boolean = false;
  var mData as Object?;

  function isDisabled() as Boolean {
    return mBGDisabled;
  }
  // var methodOnBeforeWebrequest = null;

  var methodBackgroundData as Method?;
  function setOnBackgroundData(objInstance as Object?, callback as Symbol) as Void {
    methodBackgroundData = new Lang.Method(objInstance, callback) as Method;
  }
  function getRequestCounter() as Number {
    return mRequestCounter;
  }
  function initialize() {}
  function setCurrentLocation(currentLocation as CurrentLocation) as Void {
    mCurrentLocation = currentLocation;
  }

  function setMinimalGPSLevel(level as Number) as Void {
    mMinimalGPSLevel = level;
  }
  function setUpdateFrequencyInMinutes(minutes as Number) as Void {
    if (minutes < 5) {
      minutes = 5;
    }
    mUpdateFrequencyInMinutes = minutes;
  }
  function Disable() as Void {
    try {
      Background.deleteTemporalEvent();
    } catch (ex) {
      System.println(ex.getErrorMessage());
      ex.printStackTrace();
    }
    mBGDisabled = true;
  }
  function Enable() as Void {
    mBGDisabled = false;
    reset();
  }
  function setObservationTimeDelayedMinutes(minutes as Number) as Void {
    mObservationTimeDelayedMinutesThreshold = minutes;
  }
  function isDataDelayed() as Boolean {
    return $.isDelayedFor(mLastObservationMoment, mObservationTimeDelayedMinutesThreshold);
  }
  function isEnabled() as Boolean {
    return !mBGDisabled;
  }
  function isActive() as Boolean {
    return !mBGActive;
  }
  function hasError() as Boolean {
    return mError != CustomErrors.ERROR_BG_NONE || mHttpStatus != HTTP_OK;
  }
  function reset() as Void {
    System.println("Reset BG service");
    mError = 0;
    mHttpStatus = HTTP_OK;
    mErrorMessage = "";
  }
  function onCompute(info as Activity.Info) as Void {
    mPhoneConnected = System.getDeviceSettings().phoneConnected;
    if (mCurrentLocation != null) {
      mCurrentLocation.onCompute(info);
    }
  }

  function autoScheduleService() as Void {
    if (mBGDisabled) {
      return;
    }

    try {
      testOnNonFatalError();

      // @@?? disable temporary when position not changed ( less than x km
      // distance) and last call < x minutes?
      if (hasError()) {
        stopBGservice();
        return;
      }

      startBGservice();
    } catch (ex) {
      System.println(ex.getErrorMessage());
      ex.printStackTrace();
    }
    // Doesnt work!
    // finally {
    //     mError = error;
    //     if (error !=BGService.ERROR_BG_NONE) {
    //         stopBGservice();
    //     }
    // }
  }

  hidden function testOnNonFatalError() as Void {
    if (
      mError == CustomErrors.ERROR_BG_GPS_LEVEL ||
      mError == CustomErrors.ERROR_BG_NO_PHONE ||
      mError == CustomErrors.ERROR_BG_NO_POSITION ||
      mError == CustomErrors.ERROR_BG_EXCEPTION
    ) {
      mError = CustomErrors.ERROR_BG_NONE;
    }

    if (!mPhoneConnected) {
      mError = CustomErrors.ERROR_BG_NO_PHONE;
    } else if (mCurrentLocation != null) {
      var currentLocation = mCurrentLocation as CurrentLocation;
      // @@ first request, use last location
      if (mRequestCounter > 0 && currentLocation.getAccuracy() < mMinimalGPSLevel) {
        mError = CustomErrors.ERROR_BG_GPS_LEVEL;
      } else if (!currentLocation.hasLocation()) {
        mError = CustomErrors.ERROR_BG_NO_POSITION;
      }
    }
  }

  function stopBGservice() as Void {
    if (!mBGActive) {
      return;
    }
    try {
      Background.deleteTemporalEvent();
      mBGActive = false;
      // mError =BGService.ERROR_BG_NONE; //- Keep the last error
      System.println("stopBGservice stopped");
    } catch (ex) {
      System.println("4");
      System.println(ex.getErrorMessage());
      ex.printStackTrace();
      mError = CustomErrors.ERROR_BG_EXCEPTION;
      mBGActive = false;
    }
  }

  function startBGservice() as Void {
    if (mBGDisabled) {
      System.println("startBGservice Service is disabled, no scheduling");
      return;
    }
    if (mBGActive) {
      System.println("startBGservice already active");
      return;
    }

    try {
      if (Toybox.System has :ServiceDelegate) {
        mBGActive = true;
        mError = CustomErrors.ERROR_BG_NONE;
        mHttpStatus = HTTP_OK;
        Background.registerForTemporalEvent(new Time.Duration(mUpdateFrequencyInMinutes * 60));
        System.println("startBGservice registerForTemporalEvent scheduled");
      } else {
        System.println("Unable to start BGservice (no registerForTemporalEvent)");
        mBGActive = false;
        mError = CustomErrors.ERROR_BG_NOT_SUPPORTED;
      }
    } catch (ex) {
      System.println("5");
      System.println(ex.getErrorMessage());
      ex.printStackTrace();
      mError = CustomErrors.ERROR_BG_EXCEPTION;
      mBGActive = false;
    }
  }

  function getWhenNextRequest(defValue as String?) as String? {
    if (hasError() || mBGDisabled || !mBGActive) {
      return defValue;
    }
    var lastTime = Background.getLastTemporalEventTime();
    if (lastTime == null) {
      return defValue;
    }
    var elapsedSeconds = Time.now().value() - lastTime.value();
    var secondsToNext = mUpdateFrequencyInMinutes * 60 - elapsedSeconds;
    return $.secondsToShortTimeString(secondsToNext, "{m}:{s}");
  }

  function onBackgroundData(
    data as Application.PropertyValueType /*, obj as Object, cbProcessData as Symbol*/
  ) as Void {
    mLastRequestMoment = Time.now();
    mErrorMessage = "";
    if (data instanceof Lang.Number) {
      // Check for known error else http status
      var code = data as Lang.Number;
      if (code < 0) {
        mError = code;
      } else {
        mHttpStatus = code;
        mError = CustomErrors.ERROR_BG_HTTPSTATUS;
      }
      System.println("onBackgroundData error responsecode: " + data);
      return;
    }

    if (data != null) {
      var bgData = data as Dictionary;
      if (bgData["error"] != null && bgData["status"] != null) {
        mErrorMessage = Lang.format("$1$ $2$", [bgData["status"] as Number, bgData["error"] as String]);
        System.println("onBackgroundData error OWM: " + mErrorMessage);
        return;
      }
    }

    mHttpStatus = HTTP_OK;
    // TODO
    // if (mCacheBgData && data != null) {
    //   mData = data;
    // }
    mError = CustomErrors.ERROR_BG_NONE;
    mRequestCounter = mRequestCounter + 1;

    // var processData = new Lang.Method(obj, cbProcessData);
    // processData.invoke(self, data);

    if (methodBackgroundData != null) {
      (methodBackgroundData as Method).invoke(data);
    }
  }
  function setLastObservationMoment(moment as Time.Moment?) as Void {
    mLastObservationMoment = moment;
  }

  function getStatus() as Lang.String {
    if (mBGDisabled) {
      return "Disabled";
    }
    if (mBGActive) {
      return "Active";
    }
    if (!mBGActive) {
      return "Inactive";
    }
    return "";
  }

  function getCounterStats() as Lang.String {
    return mRequestCounter.format("%0d");
  }

  function getError() as Lang.String {
    if (mHttpStatus != HTTP_OK) {
      return "Http [" + mHttpStatus.format("%0d") + "]";
    }
    return getCommunicationError(mError, mHttpStatus);
  }

  function getErrorMessage() as Lang.String {
    if (mErrorMessage.length() > 30) {
      return mErrorMessage.substring(0, 30) as String;
    }
    return mErrorMessage;
  }
}

// (:typecheck(disableBackgroundCheck))
// function getCachedBgData() as Dictionary? {
//   try {
//     var data = Storage.getValue("latest_bgData");
//     if (data == null) {
//       return null;
//     }
//     return data as Dictionary;
//   } catch (ex) {
//     ex.printStackTrace();
//   }
//   return null;
// }

// (:typecheck(disableBackgroundCheck))
// function setCachedBgData(data as Dictionary) as Void {
//   try {
//     Storage.setValue("latest_bgData", data as String) ;
//   } catch (ex) {
//     ex.printStackTrace();
//   }
// }
