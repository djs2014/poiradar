import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Time;
import Toybox.System;
import Toybox.Background;
import Toybox.Application.Storage;
using Toybox.Position;

var _BGServiceHandler as BGServiceHandler?;
// var _bgData as PoiData?;
var gDebug as Boolean = false;
var gPauseApp as Boolean = false;
var gDistance_grayscale as Boolean = false;
var gCacheBgData as Boolean = false;
var gMinimalGPSquality as Number = 3;

var g_lf_ShowWptDirection as Boolean = false;
var g_lf_ShowWptDistance as Boolean = true;
var g_lf_ShowCircleDistance as Boolean = true;
var g_lf_ShowTrack as Boolean = true;
var g_lf_HighContrast as Boolean = true;
var g_lf_ExtraRangeInMeter as Number = 150;
var g_lf_FixedRangeInMeter as Number = 0;
// # include more wpts in zoom
var g_lf_ZoomMinWayPoints as Number = 1;
var g_lf_zoomOneMeters as Number = 500;

var g_wf_ShowWptDirection as Boolean = false;
var g_wf_ShowWptDistance as Boolean = true;
var g_wf_ShowCircleDistance as Boolean = true;
var g_wf_ShowTrack as Boolean = true;
var g_wf_HighContrast as Boolean = true;
var g_wf_ExtraRangeInMeter as Number = 50;
var g_wf_FixedRangeInMeter as Number = 0;
var g_wf_ZoomMinWayPoints as Number = 1;
var g_wf_zoomOneMeters as Number = 500;

var g_sf_ShowWptDirection as Boolean = false;
var g_sf_ShowWptDistance as Boolean = false;
var g_sf_ShowCircleDistance as Boolean = false;
var g_sf_ShowTrack as Boolean = false;
var g_sf_HighContrast as Boolean = false;
var g_sf_ExtraRangeInMeter as Number = 50;
var g_sf_FixedRangeInMeter as Number = 0;
var g_sf_ZoomMinWayPoints as Number = 1;
var g_sf_zoomOneMeters as Number = 500;

var g_alert_closeRangeMeters as Number = 500;
var g_alert_closeRange as Boolean = true;
var g_alert_proximityMeters as Number = 25;
var g_alert_proximity as Boolean = true;

var g_loosefocusafterhit as Boolean = true;

var g_alert_startAfterX as Number = 30;
var g_alert_startAfterUnits as AfterXUnits = AfterXKilometer;
var gAlert_sound as SoundMode = SMOneBeep;

// x km from start quiet
var g_alert_quiet_start as Float = 0.0f;

var g_bg_timeout_seconds as Number = 0;
var g_bg_delay_seconds as Number = 0;

(:background)
var _mostRecentData as PoiData?;

(:background)
class poiradarApp extends Application.AppBase {
  var mCachedDataLoaded as Boolean = false;

  function initialize() {
    AppBase.initialize();
  }

  // onStart() is called on application start up
  function onStart(state as Dictionary?) as Void { }

  // onStop() is called when your application is exiting
  function onStop(state as Dictionary?) as Void {}

  (:typecheck(disableBackgroundCheck))
  function getInitialView() as [WatchUi.Views] or [WatchUi.Views, WatchUi.InputDelegates] {
    loadUserSettings();
    return [new poiradarView()];
  }

  //! Return the settings view and delegate for the app
  //! @return Array Pair [View, Delegate]
  (:typecheck(disableBackgroundCheck))
  function getSettingsView() as [WatchUi.Views] or [WatchUi.Views, WatchUi.InputDelegates] or Null {
    return [new $.DataFieldSettingsView(), new $.DataFieldSettingsDelegate()];
  }

  (:typecheck(disableBackgroundCheck))
  function onSettingsChanged() as Void {
    loadUserSettings();
  }

  (:typecheck(disableBackgroundCheck))
  function getBGServiceHandler() as BGServiceHandler {
    if ($._BGServiceHandler == null) {
      $._BGServiceHandler = new BGServiceHandler();
    }
    return $._BGServiceHandler as BGServiceHandler;
  }

  (:typecheck(disableBackgroundCheck))
  function loadUserSettings() as Void {
    try {
      System.println("Loading user settings");

      var reset = Storage.getValue("resetDefaults");
      if (reset == null || (reset as Boolean)) {
        System.println("Reset user settings");
        Storage.setValue("resetDefaults", false);
        Storage.setValue("debug", false);
        Storage.setValue("pause_app", false);
        // Storage.setValue("cacheBgData", false);
        Storage.setValue("distance_grayscale", false);

        Storage.setValue("checkIntervalMinutes", 5);
        Storage.setValue("maxRangeMeters", 15000);
        Storage.setValue("maxWaypoints", 40);

        Storage.setValue("lf_showWptDirection", $.g_lf_ShowWptDirection);
        Storage.setValue("lf_showWptDistance", $.g_lf_ShowWptDistance);
        Storage.setValue("lf_ShowCircleDistance", $.g_lf_ShowCircleDistance);
        Storage.setValue("lf_ShowTrack", $.g_lf_ShowTrack);
        Storage.setValue("lf_HighContrast", $.g_lf_HighContrast);
        Storage.setValue("lf_extraRangeMeters", $.g_lf_ExtraRangeInMeter);
        Storage.setValue("lf_fixedRangeMeters", $.g_lf_FixedRangeInMeter);
        Storage.setValue("lf_zoomMinWaypoints", $.g_lf_ZoomMinWayPoints);
        Storage.setValue("lf_zoomOneMeters", $.g_lf_zoomOneMeters);

        Storage.setValue("sf_showWptDirection", $.g_sf_ShowWptDirection);
        Storage.setValue("sf_showWptDistance", $.g_sf_ShowWptDistance);
        Storage.setValue("sf_extraRangeMeters", $.g_sf_ExtraRangeInMeter);
        Storage.setValue("sf_ShowTrack", $.g_sf_ShowTrack);
        Storage.setValue("sf_HighContrast", $.g_sf_HighContrast);
        Storage.setValue("sf_ShowCircleDistance", $.g_sf_ShowCircleDistance);
        Storage.setValue("sf_fixedRangeMeters", $.g_sf_FixedRangeInMeter);
        Storage.setValue("sf_zoomMinWaypoints", $.g_sf_ZoomMinWayPoints);
        Storage.setValue("sf_zoomOneMeters", $.g_sf_zoomOneMeters);

        Storage.setValue("wf_showWptDirection", $.g_wf_ShowWptDirection);
        Storage.setValue("wf_showWptDistance", $.g_wf_ShowWptDistance);
        Storage.setValue("wf_extraRangeMeters", $.g_wf_ExtraRangeInMeter);
        Storage.setValue("wf_ShowCircleDistance", $.g_wf_ShowCircleDistance);
        Storage.setValue("wf_ShowTrack", $.g_wf_ShowTrack);
        Storage.setValue("wf_HighContrast", $.g_wf_HighContrast);
        Storage.setValue("wf_fixedRangeMeters", $.g_wf_FixedRangeInMeter);
        Storage.setValue("wf_zoomMinWaypoints", $.g_wf_ZoomMinWayPoints);
        Storage.setValue("wf_zoomOneMeters", $.g_wf_zoomOneMeters);

        Storage.setValue("alert_closeRangeMeters", $.g_alert_closeRangeMeters);
        Storage.setValue("alert_closeRange", $.g_alert_closeRange);
        Storage.setValue("alert_proximityMeters", $.g_alert_proximityMeters);
        Storage.setValue("alert_proximity", $.g_alert_proximity);
        // @@ refactor, remove
        Storage.setValue("alert_startAfterX", $.g_alert_startAfterX);
        Storage.setValue("alert_startAfterUnits", $.g_alert_startAfterUnits);
        Storage.setValue("alert_sound", SMOneBeep);
        Storage.setValue("alert_quiet_start", 0.0f);

        Storage.setValue("loosefocusafterhit", $.g_loosefocusafterhit);

        Storage.setValue("poiUrl", "https://poi.castlephoto.info/poi/");
        Storage.setValue("poiAPIKey", "0548b3c7-61bc-4afc-b6e5-616f19d3cf23");
      }

      $.gDebug = $.getStorageValue("debug", $.gDebug) as Boolean;
      $.gPauseApp = $.getStorageValue("pause_app", $.gDebug) as Boolean;
      // $.gCacheBgData = $.getStorageValue("cacheBgData", $.gCacheBgData) as Boolean;
      $.gDistance_grayscale = $.getStorageValue("distance_grayscale", $.gDistance_grayscale) as Boolean;

      $.g_bg_timeout_seconds = $.getStorageValue("g_bg_timeout_seconds", $.g_bg_timeout_seconds) as Number;
      $.g_bg_delay_seconds = $.getStorageValue("g_bg_delay_seconds", $.g_bg_delay_seconds) as Number;

      $.g_lf_ShowWptDirection = $.getStorageValue("lf_showWptDirection", $.g_lf_ShowWptDirection) as Boolean;
      $.g_lf_ShowWptDistance = $.getStorageValue("lf_showWptDistance", $.g_lf_ShowWptDistance) as Boolean;
      $.g_lf_ShowCircleDistance = $.getStorageValue("lf_ShowCircleDistance", $.g_lf_ShowCircleDistance) as Boolean;
      $.g_lf_ShowTrack = $.getStorageValue("lf_ShowTrack", $.g_lf_ShowTrack) as Boolean;
      $.g_lf_HighContrast = $.getStorageValue("lf_HighContrast", $.g_lf_HighContrast) as Boolean;
      $.g_lf_ExtraRangeInMeter = $.getStorageValue("lf_extraRangeMeters", $.g_lf_ExtraRangeInMeter) as Number;
      $.g_lf_FixedRangeInMeter = $.getStorageValue("lf_fixedRangeMeters", $.g_lf_FixedRangeInMeter) as Number;
      $.g_lf_ZoomMinWayPoints = $.getStorageValue("lf_zoomMinWaypoints", $.g_lf_ZoomMinWayPoints) as Number;
      $.g_lf_zoomOneMeters = $.getStorageValue("lf_zoomOneMeters", $.g_lf_zoomOneMeters) as Number;

      $.g_sf_ShowWptDirection = $.getStorageValue("sf_showWptDirection", $.g_sf_ShowWptDirection) as Boolean;
      $.g_sf_ShowWptDistance = $.getStorageValue("sf_showWptDistance", $.g_sf_ShowWptDistance) as Boolean;
      $.g_sf_ShowCircleDistance = $.getStorageValue("sf_ShowCircleDistance", $.g_sf_ShowCircleDistance) as Boolean;
      $.g_sf_ShowTrack = $.getStorageValue("sf_ShowTrack", $.g_sf_ShowTrack) as Boolean;
      $.g_sf_HighContrast = $.getStorageValue("sf_HighContrast", $.g_sf_HighContrast) as Boolean;
      $.g_sf_ExtraRangeInMeter = $.getStorageValue("sf_extraRangeMeters", $.g_sf_ExtraRangeInMeter) as Number;
      $.g_sf_FixedRangeInMeter = $.getStorageValue("sf_fixedRangeMeters", $.g_sf_FixedRangeInMeter) as Number;
      $.g_sf_ZoomMinWayPoints = $.getStorageValue("sf_zoomMinWaypoints", $.g_sf_ZoomMinWayPoints) as Number;
      $.g_sf_zoomOneMeters = $.getStorageValue("sf_zoomOneMeters", $.g_sf_zoomOneMeters) as Number;

      $.g_wf_ShowWptDirection = $.getStorageValue("wf_showWptDirection", $.g_wf_ShowWptDirection) as Boolean;
      $.g_wf_ShowWptDistance = $.getStorageValue("wf_showWptDistance", $.g_wf_ShowWptDistance) as Boolean;
      $.g_wf_ShowCircleDistance = $.getStorageValue("wf_ShowCircleDistance", $.g_wf_ShowCircleDistance) as Boolean;
      $.g_wf_ShowTrack = $.getStorageValue("wf_ShowTrack", $.g_wf_ShowTrack) as Boolean;
      $.g_wf_HighContrast = $.getStorageValue("wf_HighContrast", $.g_wf_HighContrast) as Boolean;
      $.g_wf_ExtraRangeInMeter = $.getStorageValue("wf_extraRangeMeters", $.g_wf_ExtraRangeInMeter) as Number;
      $.g_wf_FixedRangeInMeter = $.getStorageValue("wf_fixedRangeMeters", $.g_wf_FixedRangeInMeter) as Number;
      $.g_wf_ZoomMinWayPoints = $.getStorageValue("wf_zoomMinWaypoints", $.g_wf_ZoomMinWayPoints) as Number;
      $.g_wf_zoomOneMeters = $.getStorageValue("wf_zoomOneMeters", $.g_wf_zoomOneMeters) as Number;

      $.g_alert_closeRangeMeters = $.getStorageValue("alert_closeRangeMeters", $.g_alert_closeRangeMeters) as Number;
      $.g_alert_closeRange = $.getStorageValue("alert_closeRange", $.g_alert_closeRange) as Boolean;
      $.g_alert_proximityMeters = $.getStorageValue("alert_proximityMeters", $.g_alert_proximityMeters) as Number;
      $.g_alert_proximity = $.getStorageValue("alert_proximity", $.g_alert_proximity) as Boolean;
      if ($.g_alert_proximityMeters > $.g_alert_closeRangeMeters) {
        $.g_alert_proximityMeters = $.g_alert_closeRangeMeters - 1;
        Storage.setValue("alert_proximityMeters", $.g_alert_proximityMeters);
      }
      $.g_alert_startAfterX = $.getStorageValue("alert_startAfterX", $.g_alert_startAfterX) as Number;
      $.g_alert_startAfterUnits = $.getStorageValue("alert_startAfterUnits", $.g_alert_startAfterUnits) as AfterXUnits;
      $.gAlert_sound = $.getStorageValue("alert_sound", $.gAlert_sound) as SoundMode;
      $.g_alert_quiet_start = $.getStorageValue("alert_quiet_start", $.g_alert_quiet_start) as Float;
      
      $.g_loosefocusafterhit = $.getStorageValue("loosefocusafterhit", $.g_loosefocusafterhit) as Boolean;

      var bgHandler = getBGServiceHandler();
      bgHandler.setMinimalGPSLevel($.getStorageValue("minimalGPSquality", $.gMinimalGPSquality) as Number);
      var interval = $.getStorageValue("checkIntervalMinutes", 5) as Number;
      if (interval < 5) {
        interval = 5;
        Storage.setValue("checkIntervalMinutes", interval);
      }
      bgHandler.setUpdateFrequencyInMinutes(interval);
      if ($.gPauseApp) {
        bgHandler.Disable();
      } else {
        bgHandler.Enable();
      }

      // Storage.setValue("poiUrl", "http://localhost:4000/poi/");
      // Storage.setValue("poiUrl", "https://poi.castlephoto.info/poi/");

      setStorageValueIfChanged("poiUrl", "https://poi.castlephoto.info/poi/");
      setStorageValueIfChanged("poiAPIKey", "0548b3c7-61bc-4afc-b6e5-616f19d3cf23");

      System.println("User settings loaded");
    } catch (ex) {
      System.println(ex.getErrorMessage());
      ex.printStackTrace();
    }
  }

  (:typecheck(disableBackgroundCheck))
  function setStorageValueIfChanged(key as String, def as String) as Void {
    try {
      var propertyValue = $.getApplicationProperty(key, "") as String;
      if (propertyValue.length() == 0) {
        propertyValue = def;
      }
      if (propertyValue.length() > 0) {
        var storageValue = Storage.getValue(key);
        if (storageValue == null || !(storageValue as String).equals(propertyValue)) {
          Storage.setValue(key, propertyValue);
          System.println("Storage [" + key + "] set to [" + propertyValue + "]");
        }
      }
    } catch (ex) {
      System.println(ex.getErrorMessage());
      ex.printStackTrace();
    }
  }

  public function getServiceDelegate() as [System.ServiceDelegate] {
    return [new BackgroundServiceDelegate()];
  }

  (:typecheck(disableBackgroundCheck))
  function onBackgroundData(data as Application.PersistableType) as Void {
    System.println("Background data recieved");
    // System.println(data);

    if (data instanceof Lang.Number && data == 0) {
      System.println("Response code is 0 -> reset bg service");
      loadUserSettings();
      return;
    }

    var bgHandler = getBGServiceHandler();
    bgHandler.onBackgroundData(data); //, self, :updateBgData);

    WatchUi.requestUpdate();
  }
}

function getApp() as poiradarApp {
  return Application.getApp() as poiradarApp;
}
