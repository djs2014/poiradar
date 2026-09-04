import Toybox.Application.Storage;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Application;

var gExitedMenu as Boolean = false;

//! Initial view for the settings
class DataFieldSettingsView extends WatchUi.View {
  //! Constructor
  function initialize() {
    View.initialize();
  }

  //! Update the view
  //! @param dc Device context
  function onUpdate(dc as Dc) as Void {
    dc.clearClip();
    dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
    dc.clear();
    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

    var mySettings = System.getDeviceSettings();
    var version = mySettings.monkeyVersion;
    var versionString = Lang.format("$1$.$2$.$3$", version);

    dc.drawText(
      dc.getWidth() / 2,
      dc.getHeight() / 2 - 30,
      Graphics.FONT_SMALL,
      "Press Menu \nfor settings \nCIQ " + versionString,
      Graphics.TEXT_JUSTIFY_CENTER
    );
  }
}

//! Handle opening the settings menu
class DataFieldSettingsDelegate extends WatchUi.BehaviorDelegate {
  //! Constructor
  function initialize() {
    BehaviorDelegate.initialize();
  }

  //! Handle the menu event
  //! @return true if handled, false otherwise
  function onMenu() as Boolean {
    var menu = new $.DataFieldSettingsMenu();
    var mi = new WatchUi.MenuItem("Proxy", "Poi server config", "proxy", null);
    menu.addItem(mi);
    mi = new WatchUi.MenuItem("Large field", null, "largefield", null);
    menu.addItem(mi);
    mi = new WatchUi.MenuItem("Wide field", null, "widefield", null);
    menu.addItem(mi);
    mi = new WatchUi.MenuItem("Small field", null, "smallfield", null);
    menu.addItem(mi);
    mi = new WatchUi.MenuItem("Alerts", null, "alerts", null);
    menu.addItem(mi);
    mi = new WatchUi.MenuItem("Sound", null, "sound", null);
    menu.addItem(mi);
    mi = new WatchUi.MenuItem("Advanced", null, "advanced", null);
    menu.addItem(mi);

    var boolean = false;

    boolean = Storage.getValue("debug") ? true : false;
    menu.addItem(new WatchUi.ToggleMenuItem("Debug", null, "debug", boolean, null));
    boolean = Storage.getValue("resetDefaults") ? true : false;
    menu.addItem(new WatchUi.ToggleMenuItem("Reset to defaults", null, "resetDefaults", boolean, null));
    
    boolean = Storage.getValue("pause_app") ? true : false;
    menu.addItem(new WatchUi.ToggleMenuItem("Pause app", null, "pause_app", boolean, null));

    var view = new $.DataFieldSettingsView();
    WatchUi.pushView(menu, new $.DataFieldSettingsMenuDelegate(view), WatchUi.SLIDE_IMMEDIATE);
    return true;
  }

  function onBack() as Boolean {
    getApp().onSettingsChanged();    
    $.gExitedMenu = true;
    return false;
  }
}

function getStorageNumberAsString(key as String) as String {
  return (getStorageValue(key, 0) as Number).format("%0d");
}

function getStorageFloatAsString(key as String) as String {
  return (getStorageValue(key, 0) as Float).format("%0.1f");
}

function getMinimalGPSqualityText(value as Number) as String {
  switch (value) {
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

function getStartAfterUnitsText(value as AfterXUnits) as String {
  switch (value) {
    case AfterXKilometer:
      return "Kilometer";
    case AfterXMinutes:
      return "Minutes";
    default:
      return "Kilometer";
  }
}
function getSoundModeText(value as SoundMode) as String {
  switch (value) {
    case SMSilent:
      return "No sound";
    case SMOneBeep:
      return "1 beep";
    case SMBeepPerPoi:
      return "Beep per poi";
    default:
      return "--";
  }
}

var maxPOIsets as Number = 7;
enum POISet {
  POISET_RIVM = 0,
  POISET_OSM = 1,
  POISET_OSM_WATERPOINTS = 2,
  POISET_OSM_TOILETS = 3,
  POISET_ALPS = 4,
  POISET_PYRENEES = 5,
  POISET_NL = 6,  
}

function toPOISet(value as Number) as POISet {
  switch (value) {
    case 0:
      return POISET_RIVM;
    case 1:
      return POISET_OSM;
    case 2:
      return POISET_OSM_WATERPOINTS;
    case 3:
      return POISET_OSM_TOILETS;
    case 4:
      return POISET_ALPS;
    case 5:
      return POISET_PYRENEES;
    case 6:
      return POISET_NL;
    default:
      return POISET_RIVM;
  }
}
function getPOIsetText(value as Number) as String {
  switch (value) {
    case POISET_RIVM:
      return "NL drinking water RIVM";
    case POISET_OSM:
      return "OSM";
    case POISET_OSM_WATERPOINTS:
      return "OSM waterpoints";
    case POISET_OSM_TOILETS:
      return "OSM public toilets";
    case POISET_ALPS:
      return "Alps";
    case POISET_PYRENEES:
      return "Pyrenees";    
    case POISET_NL:
      return "Netherlands";
    default:
      return "RIVM drinking water";
  }
}


function subMenuToggleMenuItem(key as String) as String {
  // if (key.equals("show_timer")) {
  //   if (Storage.getValue(key) ? true : false) {
  //     return "timer time";
  //   } else {
  //     return "elapsed time";
  //   }
  // }
  // else if (key.equals("wf_toggle_heading")) {
  //   if (Storage.getValue(key) ? true : false) {
  //     return "distance (next)";
  //   } else {
  //     return "heading";
  //   }
  // }
  return "";
}
