import Toybox.Application;
import Toybox.Application.Storage;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.System;

// display menu items based on list/enums
class selectionMenuPicker {
  var _menu as WatchUi.Menu2;
  var _onSelectedCb as Method?;
  var _storageKey as String;
  var _mi as MenuItem?;

  function initialize(title as String, storageKey as String) {
    _menu = new WatchUi.Menu2({ :title => title });
    _storageKey = storageKey;
  }

  function add(label as String, subLabel as String?, value as Object) as Void {
    // identifier will contain selected value
    var mi = new WatchUi.MenuItem(label, subLabel, value, null);
    _menu.addItem(mi);
  }

  // :onselect(value)
  function setOnSelected(objInstance as Object, method as Symbol, mi as MenuItem) as Void {
    _onSelectedCb = new Method(objInstance, method) as Method;
    _mi = mi;
  }

  function onSelected(value as Object, label as String) as Void {
    if (_onSelectedCb == null) {
      return;
    }
    //(_onSelectedCb as Method(value as Object, storageKey as String)).invoke(value, _storageKey);
    (_onSelectedCb as Method).invoke(value, _storageKey);
    if (_mi != null) {
    _mi.setSubLabel(label);
    }
  }

  function show() as Void {
    WatchUi.pushView(_menu, new $.SelectionMenuDelegate(self), WatchUi.SLIDE_UP);
  }
}

class SelectionMenuDelegate extends WatchUi.Menu2InputDelegate {
  hidden var _delegate as selectionMenuPicker;

   function initialize(delegate as selectionMenuPicker) {
    Menu2InputDelegate.initialize();
    _delegate = delegate;
  }

   function onSelect(item as MenuItem) as Void {
    var id = item.getId();
    if (id != null) {
    _delegate.onSelected(id as Object, item.getLabel());
    }
    onBack();
    return;
  }

  //! Handle the back key being pressed
   function onBack() as Void {
    WatchUi.popView(WatchUi.SLIDE_DOWN);
  }

  //! Handle the done item being selected
   function onDone() as Void {
    WatchUi.popView(WatchUi.SLIDE_DOWN);
  }
}
