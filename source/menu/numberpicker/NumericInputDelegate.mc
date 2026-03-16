using Toybox.System;
using Toybox.WatchUi;
using Toybox.Lang;

// Note that on wearable products, input events are not supported for data fields.
class NumericInputDelegate extends WatchUi.BehaviorDelegate {
  var _view as NumericInputView;

  function initialize(view as NumericInputView) {
    WatchUi.BehaviorDelegate.initialize();
    _view = view;
  }

  function onTap(event as WatchUi.ClickEvent) {
    return _view.onKeyPressed(event.getCoordinates());
  }

  function onKey(keyEvent as WatchUi.KeyEvent) {
    return _view.onKeyEvent(keyEvent);    
  }
}
