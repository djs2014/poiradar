using Toybox.System;
using Toybox.WatchUi;
using Toybox.Lang;

// Note that on wearable products, input events are not supported for data fields. 
// class NumericInputDelegate extends WatchUi.InputDelegate {
class NumericInputDelegate extends WatchUi.BehaviorDelegate {
  var _debug as Lang.Boolean = false;
  var _view as NumericInputView;

   function initialize(debug as Lang.Boolean, view as NumericInputView) {
    WatchUi.BehaviorDelegate.initialize();
    _debug = debug;
    _view = view;    
  }

  function onTap(event as WatchUi.ClickEvent) {
    if (_debug) {
      _view.setDebugInfo("onTap", event.getCoordinates());
    }
    _view.onKeyPressed(event.getCoordinates());   
    return true;
  }
}
