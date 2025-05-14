import Toybox.Application;
import Toybox.Application.Storage;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.System;

class DataFieldSettingsMenu extends WatchUi.Menu2 {
  function initialize() {
    Menu2.initialize({ :title => "Settings" });
  }
}

//! Handles menu input and stores the menu data
class DataFieldSettingsMenuDelegate extends WatchUi.Menu2InputDelegate {
  hidden var _currentMenuItem as MenuItem?;
  hidden var _view as DataFieldSettingsView;

  function initialize(view as DataFieldSettingsView) {
    Menu2InputDelegate.initialize();
    _view = view;
  }

  function onSelect(menuItem as MenuItem) as Void {
    _currentMenuItem = menuItem;
    var id = menuItem.getId();

    if (id instanceof String && id.equals("proxy")) {
      var proxyMenu = new WatchUi.Menu2({ :title => "Poi server config" });

      var mi = new WatchUi.MenuItem("Minimal GPS", null, "minimalGPSquality", null);
      var value = getStorageValue(mi.getId() as String, $.gMinimalGPSquality) as Number;
      mi.setSubLabel($.getMinimalGPSqualityText(value));
      proxyMenu.addItem(mi);
      // @@ url - text picker
      // @@ apikey - text picker
      mi = new WatchUi.MenuItem("Checkinterval minutes", null, "checkIntervalMinutes", null);
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      proxyMenu.addItem(mi);
      mi = new WatchUi.MenuItem("Max range meters", null, "maxRangeMeters", null);
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      proxyMenu.addItem(mi);
      mi = new WatchUi.MenuItem("Max waypoints", null, "maxWaypoints", null);
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      proxyMenu.addItem(mi);

      mi = new WatchUi.MenuItem("Background timeout sec", null, "g_bg_timeout_seconds", null);
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      proxyMenu.addItem(mi);

      // @@ set - watertappunt custom sets?

      // @@ need more testing ... max memory saving
      // var boolean = Storage.getValue("cacheBgData") ? true : false;
      // proxyMenu.addItem(new WatchUi.ToggleMenuItem("Cache waypoints", null, "cacheBgData", boolean, null));

      WatchUi.pushView(proxyMenu, new $.GeneralMenuDelegate(), WatchUi.SLIDE_UP);
      return;
    }
    if (id instanceof String && id.equals("largefield")) {
      var lfMenu = new WatchUi.Menu2({ :title => "Large field" });

      var boolean = Storage.getValue("lf_showWptDirection") ? true : false;
      lfMenu.addItem(new WatchUi.ToggleMenuItem("Waypoint direction", null, "lf_showWptDirection", boolean, null));
      boolean = Storage.getValue("lf_showWptDistance") ? true : false;
      lfMenu.addItem(new WatchUi.ToggleMenuItem("Waypoint distance", null, "lf_showWptDistance", boolean, null));
      boolean = Storage.getValue("lf_ShowCircleDistance") ? true : false;
      lfMenu.addItem(new WatchUi.ToggleMenuItem("Distance label", null, "lf_ShowCircleDistance", boolean, null));
      boolean = Storage.getValue("lf_ShowTrack") ? true : false;
      lfMenu.addItem(new WatchUi.ToggleMenuItem("Track", null, "lf_ShowTrack", boolean, null));

      var mi = new WatchUi.MenuItem("Extra range meters", null, "lf_extraRangeMeters", null);
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      lfMenu.addItem(mi);

      mi = new WatchUi.MenuItem("Fixed range meters", null, "lf_fixedRangeMeters", null);
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      lfMenu.addItem(mi);

      mi = new WatchUi.MenuItem("Zoom # waypoints", null, "lf_zoomMinWaypoints", null);
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      lfMenu.addItem(mi);

      mi = new WatchUi.MenuItem("Zoom on 1 meters", null, "lf_zoomOneMeters", null);
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      lfMenu.addItem(mi);

      WatchUi.pushView(lfMenu, new $.GeneralMenuDelegate(), WatchUi.SLIDE_UP);
      return;
    }
    if (id instanceof String && id.equals("smallfield")) {
      var sfMenu = new WatchUi.Menu2({ :title => "Small field" });

      var boolean = Storage.getValue("sf_showWptDirection") ? true : false;
      sfMenu.addItem(new WatchUi.ToggleMenuItem("Waypoint direction", null, "sf_showWptDirection", boolean, null));
      boolean = Storage.getValue("sf_showWptDistance") ? true : false;
      sfMenu.addItem(new WatchUi.ToggleMenuItem("Waypoint distance", null, "sf_showWptDistance", boolean, null));
      boolean = Storage.getValue("sf_ShowCircleDistance") ? true : false;
      sfMenu.addItem(new WatchUi.ToggleMenuItem("Distance label", null, "sf_ShowCircleDistance", boolean, null));
      boolean = Storage.getValue("sf_ShowTrack") ? true : false;
      sfMenu.addItem(new WatchUi.ToggleMenuItem("Track", null, "sf_ShowTrack", boolean, null));

      var mi = new WatchUi.MenuItem("Extra range meters", null, "sf_extraRangeMeters", null);
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      sfMenu.addItem(mi);

      mi = new WatchUi.MenuItem("Fixed range meters", null, "sf_fixedRangeMeters", null);
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      sfMenu.addItem(mi);

      mi = new WatchUi.MenuItem("Zoom # waypoints", null, "sf_zoomMinWaypoints", null);
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      sfMenu.addItem(mi);

      mi = new WatchUi.MenuItem("Zoom on 1 meters", null, "sf_zoomOneMeters", null);
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      sfMenu.addItem(mi);

      WatchUi.pushView(sfMenu, new $.GeneralMenuDelegate(), WatchUi.SLIDE_UP);
      return;
    }
    if (id instanceof String && id.equals("widefield")) {
      var tfMenu = new WatchUi.Menu2({ :title => "Wide field" });

      var boolean = Storage.getValue("wf_showWptDirection") ? true : false;
      tfMenu.addItem(new WatchUi.ToggleMenuItem("Waypoint direction", null, "wf_showWptDirection", boolean, null));
      boolean = Storage.getValue("wf_showWptDistance") ? true : false;
      tfMenu.addItem(new WatchUi.ToggleMenuItem("Waypoint distance", null, "wf_showWptDistance", boolean, null));
      boolean = Storage.getValue("wf_ShowCircleDistance") ? true : false;
      tfMenu.addItem(new WatchUi.ToggleMenuItem("Distance label", null, "wf_ShowCircleDistance", boolean, null));
      boolean = Storage.getValue("wf_ShowTrack") ? true : false;
      tfMenu.addItem(new WatchUi.ToggleMenuItem("Track", null, "wf_ShowTrack", boolean, null));

      var mi = new WatchUi.MenuItem("Extra range meters", null, "wf_extraRangeMeters", null);
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      tfMenu.addItem(mi);

      mi = new WatchUi.MenuItem("Fixed range meters", null, "wf_fixedRangeMeters", null);
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      tfMenu.addItem(mi);

      mi = new WatchUi.MenuItem("Zoom # waypoints", null, "wf_zoomMinWaypoints", null);
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      tfMenu.addItem(mi);

      mi = new WatchUi.MenuItem("Zoom on 1 meters", null, "wf_zoomOneMeters", null);
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      tfMenu.addItem(mi);

      WatchUi.pushView(tfMenu, new $.GeneralMenuDelegate(), WatchUi.SLIDE_UP);
      return;
    }
    if (id instanceof String && id.equals("alerts")) {
      var alertMenu = new WatchUi.Menu2({ :title => "Alerts" });

      var mi = new WatchUi.MenuItem("Close range meters", null, "alert_closeRangeMeters", null);
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      alertMenu.addItem(mi);

      var boolean = Storage.getValue("alert_closeRange") ? true : false;
      alertMenu.addItem(new WatchUi.ToggleMenuItem("Beep close range", null, "alert_closeRange", boolean, null));

      mi = new WatchUi.MenuItem("Proximity meters", null, "alert_proximityMeters", null);
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      alertMenu.addItem(mi);

      boolean = Storage.getValue("alert_proximity") ? true : false;
      alertMenu.addItem(new WatchUi.ToggleMenuItem("Beep proximity", null, "alert_proximity", boolean, null));

      boolean = Storage.getValue("loosefocusafterhit") ? true : false;
      alertMenu.addItem(new WatchUi.ToggleMenuItem("Loose focus after hit", null, "loosefocusafterhit", boolean, null));

      // @@TODO or store start location -> no beeps 'silent' in range start location < x km (for start of ride / end of ride)
      // mi = new WatchUi.MenuItem("Start after X", null, "alert_startAfterX", null);
      // mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      // alertMenu.addItem(mi);

      // mi = new WatchUi.MenuItem("Start after units", null, "alert_startAfterUnits", null);
      // var value = getStorageValue(mi.getId() as String, $.g_alert_startAfterUnits) as AfterXUnits;
      // mi.setSubLabel($.getStartAfterUnitsText(value));
      // alertMenu.addItem(mi);

      WatchUi.pushView(alertMenu, new $.GeneralMenuDelegate(), WatchUi.SLIDE_UP);
      return;
    }

    if (id instanceof String && id.equals("sound")) {
      var soundMenu = new WatchUi.Menu2({ :title => "Sound" });

      var mi = new WatchUi.MenuItem("Alert sound", null, "alert_sound", null);
      var value = getStorageValue(mi.getId() as String, $.gAlert_sound) as SoundMode;
      mi.setSubLabel($.getSoundModeText(value));
      soundMenu.addItem(mi);

      mi = new WatchUi.MenuItem("Quiet start range|0.0~200.0 (km)", null, "alert_quiet_start", null);
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String) + " km");
      soundMenu.addItem(mi);

      WatchUi.pushView(soundMenu, new $.GeneralMenuDelegate(), WatchUi.SLIDE_UP);
      return;
    }
    if (id instanceof String && menuItem instanceof ToggleMenuItem) {
      Storage.setValue(id as String, menuItem.isEnabled());
      menuItem.setSubLabel($.subMenuToggleMenuItem(id as String));
    }
  }
}

class GeneralMenuDelegate extends WatchUi.Menu2InputDelegate {
  hidden var _item as MenuItem?;
  hidden var _currentPrompt as String = "";
  hidden var _debug as Boolean = false;

  function initialize() {
    Menu2InputDelegate.initialize();
  }

  function onSelect(item as MenuItem) as Void {
    _item = item;
    var id = item.getId();
    if (id instanceof String && id.equals("minimalGPSquality")) {
      var sp = new selectionMenuPicker("Minimal GPS", id as String);
      for (var i = 0; i <= 4; i++) {
        sp.add($.getMinimalGPSqualityText(i), null, i);
      }
      sp.setOnSelected(self, :onSelectedSelection, item);
      sp.show();
      return;
    }

    if (id instanceof String && id.equals("alert_startAfterUnits")) {
      var sp = new selectionMenuPicker("Alert after", id as String);

      sp.add($.getStartAfterUnitsText(AfterXKilometer), null, AfterXKilometer);
      sp.add($.getStartAfterUnitsText(AfterXMinutes), null, AfterXMinutes);

      sp.setOnSelected(self, :onSelectedSelection, item);
      sp.show();
      return;
    }
    if (id instanceof String && id.equals("alert_sound")) {
      var sp = new selectionMenuPicker("Alert sound", id as String);
      for (var i = 0; i < 3; i++) {
        sp.add($.getSoundModeText(i as SoundMode), null, i);
      }
      sp.setOnSelected(self, :onSelectedSelection, item);
      sp.show();
      return;
    }

    // if (id instanceof String && id.equals("sound_mode")) {
    //   var sp = new selectionMenuPicker("Sound level", id as String);
    //   for (var i = 0; i <= 3; i++) {
    //     sp.add($.getSoundModeText(i), null, i);
    //   }sound
    //   sp.setOnSelected(self, :onSelectedSelection, item);
    //   sp.show();
    //   return;
    // }

    if (id instanceof String && item instanceof ToggleMenuItem) {
      Storage.setValue(id as String, item.isEnabled());
      return;
    }

    // Numeric input
    var prompt = item.getLabel();
    var value = $.getStorageValue(id as String, 0) as Numeric;
    var view = $.getNumericInputView(prompt, value);
    view.setOnAccept(self, :onAcceptNumericinput);
    view.setOnKeypressed(self, :onNumericinput);

    Toybox.WatchUi.pushView(view, new $.NumericInputDelegate(_debug, view), WatchUi.SLIDE_RIGHT);
  }

  function onAcceptNumericinput(value as Numeric, subLabel as String) as Void {
    try {
      if (_item != null) {
        var storageKey = _item.getId() as String;

        Storage.setValue(storageKey, value);
        (_item as MenuItem).setSubLabel(subLabel);
      }
    } catch (ex) {
      ex.printStackTrace();
    }
  }

  function onNumericinput(
    editData as Array<Char>,
    cursorPos as Number,
    insert as Boolean,
    negative as Boolean,
    opt as NumericOptions
  ) as Void {
    // Hack to refresh screen
    WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
    var view = new $.NumericInputView("", 0);
    view.processOptions(opt);
    view.setEditData(editData, cursorPos, insert, negative);
    view.setOnAccept(self, :onAcceptNumericinput);
    view.setOnKeypressed(self, :onNumericinput);

    Toybox.WatchUi.pushView(view, new $.NumericInputDelegate(_debug, view), WatchUi.SLIDE_IMMEDIATE);
  }

  //! Handle the back key being pressed

  function onBack() as Void {
    WatchUi.popView(WatchUi.SLIDE_DOWN);
  }

  //! Handle the done item being selected

  function onDone() as Void {
    WatchUi.popView(WatchUi.SLIDE_DOWN);
  }

  function onSelectedSelection(storageKey as String, value as Application.PropertyValueType) as Void {
    Storage.setValue(storageKey, value);
  }
}
