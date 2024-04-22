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
    mi = new WatchUi.MenuItem("Small field", null, "smallfield", null);
    menu.addItem(mi);
    mi = new WatchUi.MenuItem("Tiny field", null, "tinyfield", null);
    menu.addItem(mi);
    mi = new WatchUi.MenuItem("Alerts", null, "alerts", null);
    menu.addItem(mi);
    mi = new WatchUi.MenuItem("Sound", null, "sound", null);
    menu.addItem(mi);

    var boolean = false;

    boolean = Storage.getValue("distance_grayscale") ? true : false;
    menu.addItem(new WatchUi.ToggleMenuItem("Grayscale distance", null, "distance_grayscale", boolean, null));
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
  return (getStorageValue(key, 0) as Number).format("%.0d");
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
