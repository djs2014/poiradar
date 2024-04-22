import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.StringUtil;

//! Show the text the user picked
class NumericInputView extends WatchUi.View {
  hidden var _currentValue as Numeric;
  hidden var _prompt as String = "";
  hidden var _cursorPos as Number = -1;
  hidden var _insert as Boolean = true;
  hidden var _negative as Boolean = false;
  hidden var _nrOfItemsInRow as Number = 4;
  hidden var _debug as Boolean = false;
  hidden var _partialUpdate as Boolean = false;
  hidden var _debugInfo as String = "";

  hidden var _keyPressed as String = "";
  hidden var _keyCoord as Lang.Array<Lang.Array<Lang.Number> > = [[]] as Lang.Array<Lang.Array<Lang.Number> >;
  hidden var _controlCoord as Lang.Array<Lang.Array<Lang.Number> > = [[]] as Lang.Array<Lang.Array<Lang.Number> >;

  hidden var _keys as Array<String> = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"] as Array<String>;
  hidden var _controls as Array<String> = ["<", "BCK", "DEL", ">", "INS", "CLR", "OK"] as Array<String>;
  hidden var _valueFormat as String = "%.2f";
  hidden var _editData as Array<Char> = [] as Array<Char>;
  hidden var _lineHeight as Number = 20;
  hidden var _fontHeightMedium as Number = 20;
  hidden var _keyWidth as Number = 0;
  hidden var _margin as Number = 0;
  hidden var _space as Number = 2;
  hidden var _redrawKeyPad as Boolean = true;

  hidden var _options as NumericOptions = new NumericOptions();

  var _onAccept as Method?;
  var _onKeypressed as Method?;

  //! Constructor
  function initialize(debug as Boolean, prompt as String, value as Numeric) {
    WatchUi.View.initialize();
    _debug = debug;

    _prompt = prompt;
    _currentValue = value;

    _options = $.parseLabelToOptions(_prompt);
    processOptions(_options);

    _editData = buildEditedValue(_currentValue, _valueFormat);
    _cursorPos = _currentValue.format(_valueFormat).length();

    _keyCoord = _keyCoord.slice(0, 0);
    _controlCoord = _controlCoord.slice(0, 0);
  }

  function setEditData(editData as Array<Char>, cursorPos as Number?, insert as Boolean, negative as Boolean) as Void {
    _editData = editData;
    _currentValue = buildCurrentValue(_editData);
    if (cursorPos == null) {
      _cursorPos = _currentValue.format(_valueFormat).length();
    } else {
      _cursorPos = cursorPos as Number;
    }
    _insert = insert;
    _negative = negative;
  }

  function processOptions(options as NumericOptions) as Void {
    if (options.isFloat) {
      _currentValue = _currentValue.toFloat();
    } else {
      _currentValue = _currentValue.toNumber();
    }

    switch (_currentValue) {
      case instanceof Long:
      case instanceof Number:
        _valueFormat = "%0d";
        if (_currentValue < 0) {
          _negative = true;
          _currentValue = _currentValue * -1;
        }
        break;
      case instanceof Float:
      case instanceof Double:
        _valueFormat = "%0.2f";
        _keys.add(".");
        if (_currentValue < 0) {
          _negative = true;
          _currentValue = _currentValue * -1.0;
        }
        break;
    }

    if (options.useMinus) {
      _keys.add("-");
    }
  }

  function validateCurrentValue(value as Numeric) as Numeric {
    if (_options.minValue != 0 or _options.maxValue != 0) {
      if (_currentValue < _options.minValue) {
        _currentValue = _options.minValue;
      } else if (_options.maxValue > _options.minValue and _currentValue > _options.maxValue) {
        _currentValue = _options.maxValue;
      }
    }
    return _currentValue;
  }

  function setOnAccept(objInstance as Object, method as Symbol) as Void {
    _onAccept = new Method(objInstance, method) as Method;
  }

  function onAccept(value as Numeric) as Void {
    if (_onAccept == null) {
      return;
    }
    (_onAccept as Method).invoke(value);
    // (_onAccept as (Method(value as Numeric))).invoke(value);
  }

  function setOnKeypressed(objInstance as Object, method as Symbol) as Void {
    _onKeypressed = new Method(objInstance, method) as Method;
  }

  function refreshUi() as Void {
    // WatchUi.requestUpdate(); not working, so close current view and reopen again.
    if (_onKeypressed == null) {
      return;
    }
    (_onKeypressed as Method).invoke(_editData, _cursorPos, _insert, _negative, _options);
    // (
    //   _onKeypressed as
    //     (Method
    //       (editData as Array<Char>, cursorPos as Number, insert as Boolean)
    //     )
    // ).invoke(_editData, _cursorPos, _insert);
  }

  //! Load your resources here
  //! @param dc Device context
  function onLayout(dc as Dc) as Void {
    _lineHeight = dc.getFontHeight(Graphics.FONT_SMALL);
    _fontHeightMedium = dc.getFontHeight(Graphics.FONT_MEDIUM);

    if (dc.getHeight() < 400) {
      _nrOfItemsInRow = 6;
    }
    // Size of key squares (include the spaces between key squares)
    _keyWidth = ((dc.getWidth() - 2 * (_nrOfItemsInRow - 1) * _space) / _nrOfItemsInRow) as Number;

    _margin = ((dc.getWidth() - _keyWidth * _nrOfItemsInRow) / 2) as Number;
    _keyWidth = _keyWidth - _space;
  }

  //! Restore the state of the app and prepare the view to be shown
  function onShow() as Void {}

  // rectangle keypad 123 456 789 0. DEL OK

  //! Update the view
  //! @param dc Device context
  function onUpdate(dc as Dc) as Void {
    var y = 1;
    // var fullscreenRefresh = !_partialUpdate or _keyCoord.size() == 0;
    // view will close and open, so fullscreenr refresh!
    var fullscreenRefresh = true;
    if (fullscreenRefresh) {
      dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
      dc.clear();
    }

    drawTopInfo(dc, y);
    y = (y + 3 * _lineHeight).toNumber();

    if (fullscreenRefresh or _redrawKeyPad) {
      drawKeyPad(dc, y, _keys, _controls);
      _redrawKeyPad = false;
    }

    if (_debug) {
      drawInfoPanel(dc);
    }
  }
  hidden function buildEditedValue(value as Numeric, format as String) as Array<Char> {
    // if (value == 0.0f && !_keyPressed.equals(".")) {
    //   var stringValue = value.format("%d");
    //   return stringValue.toCharArray();
    // } else {
    var stringValue = value.format(_valueFormat);
    return stringValue.toCharArray();
    // }
  }

  // @@ TODO check if value still ok _minValue, _maxValue

  hidden function buildCurrentValue(data as Array<Char>) as Numeric {
    try {
      var stringValue = StringUtil.charArrayToString(data);

      var value = null;
      switch (_currentValue) {
        case instanceof Long:
          value = stringValue.toLong();
          break;
        case instanceof Number:
          value = stringValue.toNumber();

          break;
        case instanceof Float:
          value = stringValue.toFloat();
          break;
        case instanceof Double:
          value = stringValue.toDouble();
          break;
      }

      if (value != null) {
        return value as Numeric;
      }

      return _currentValue;
    } catch (ex) {
      ex.printStackTrace();
    }
    return _currentValue;
  }

  hidden function drawTopInfo(dc as Dc, yStart as Number) as Void {
    var y = yStart;
    var x = 1;
    var width = dc.getWidth();
    var height = 2.5 * _lineHeight;

    if (_partialUpdate) {
      dc.setClip(x, y, width, height);
      dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
      dc.clear();
    }

    dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
    dc.drawText(dc.getWidth() / 2, y, Graphics.FONT_SMALL, _prompt, Graphics.TEXT_JUSTIFY_CENTER);

    y = y + _lineHeight;
    drawEditedValue(dc, y, _editData, _insert);
    dc.clearClip();
  }

  hidden function drawEditedValue(dc as Dc, y as Number, data as Array<Char>, insert as Boolean) as Void {
    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
    var x = _margin + dc.getTextWidthInPixels("-", Graphics.FONT_MEDIUM);

    var cursor = "";
    var first = _editData.slice(0, _cursorPos);
    var last = _editData.slice(_cursorPos, null);
    if (last.size() > 0) {
      // cursor is first character of last part
      cursor = StringUtil.charArrayToString(last.slice(0, 1));
      last = last.slice(1, null);
    }

    if (_negative) {
      dc.drawText(x, y, Graphics.FONT_MEDIUM, "-", Graphics.TEXT_JUSTIFY_RIGHT);
    }
    var textFirst = StringUtil.charArrayToString(first);
    var textLast = StringUtil.charArrayToString(last);

    dc.drawText(x, y, Graphics.FONT_MEDIUM, textFirst, Graphics.TEXT_JUSTIFY_LEFT);
    x = x + dc.getTextWidthInPixels(textFirst, Graphics.FONT_MEDIUM);
    var widthCursor = 0;
    if (cursor.length() > 0) {
      widthCursor = dc.getTextWidthInPixels(cursor, Graphics.FONT_MEDIUM);
      dc.drawText(x, y, Graphics.FONT_MEDIUM, cursor, Graphics.TEXT_JUSTIFY_LEFT);
    }
    // always draw cursor line (can be also at start / end of text)
    if (insert) {
      // insert, show | after cursor pos
      dc.drawLine(x, y, x, y + _fontHeightMedium);
    } else {
      // overwrite, show a bar under key
      dc.fillRectangle(x, y + _fontHeightMedium, widthCursor, 3);
    }
    x = x + widthCursor;

    dc.drawText(x, y, Graphics.FONT_MEDIUM, textLast, Graphics.TEXT_JUSTIFY_LEFT);
  }

  hidden function drawInfoPanel(dc as Dc) as Void {
    var x = 1;
    var width = dc.getWidth();
    var height = 1 * _lineHeight;
    var y = dc.getHeight() - height;
    if (_partialUpdate) {
      dc.setClip(x, y, width, height);
      dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
      dc.clear();
    }

    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

    dc.drawText(
      dc.getWidth() / 2,
      dc.getHeight() - _lineHeight,
      Graphics.FONT_TINY,
      _debugInfo,
      Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
    );
    dc.clearClip();
  }

  //! Called when this View is removed from the screen. Save the
  //! state of your app here.
  function onHide() as Void {}

  function setDebugInfo(event as String, coord as Lang.Array<Lang.Number>) as Void {
    var key = getKeyPressed(coord);
    _debugInfo = Lang.format("Event[$1$] Coord[$2$,$3$] Key:[$4$]", [event, coord[0], coord[1], key]);
  }

  function onKeyPressed(coord as Lang.Array<Lang.Number>) as Void {
    _keyPressed = getKeyPressed(coord);

    // Controls
    if (_keyPressed.equals("<")) {
      if (_cursorPos > 0) {
        _cursorPos = _cursorPos - 1;
      }
    } else if (_keyPressed.equals(">")) {
      var maxCursorPos = _currentValue.format(_valueFormat).length();
      if (_cursorPos < maxCursorPos) {
        _cursorPos = _cursorPos + 1;
      }
    } else if (_keyPressed.equals("INS")) {
      _insert = !_insert;
      _redrawKeyPad = true;
    } else if (_keyPressed.equals("OK")) {
      // _delegate.onAcceptNumericinput(_currentValue);
      if (_negative) {
        switch (_currentValue) {
          case instanceof Long:
          case instanceof Number:
            _currentValue = _currentValue * -1;
            break;
          case instanceof Float:
          case instanceof Double:
            _currentValue = _currentValue * -1.0;
            break;
        }
      }

      _currentValue = validateCurrentValue(_currentValue);

      onAccept(_currentValue);
      WatchUi.popView(WatchUi.SLIDE_RIGHT);
      return;
    } else if (_keyPressed.equals("CLR")) {
      _currentValue = 0.0f;
      _editData = _editData.slice(0, 0);
      _cursorPos = 0;
    } else if (_keyPressed.equals("DEL")) {
      removeKey(true);
    } else if (_keyPressed.equals("BCK")) {
      removeKey(false);
    } else if (_keyPressed.equals("-")) {
      _negative = !_negative;
      _redrawKeyPad = true;
    } else {
      addKey(_keyPressed, _insert);
    }

    _currentValue = buildCurrentValue(_editData);

    //if (_debug) {
    refreshUi();
    //}
  }

  hidden function addKey(key as String, insert as Boolean) as Void {
    if (_editData.size() == 0 || _cursorPos >= _editData.size()) {
      // nothing, or cursor at the end
      _editData.addAll(key.toCharArray());
    } else {
      var first = _editData.slice(0, _cursorPos);
      var last = _editData.slice(_cursorPos, null);
      if (insert) {
        _editData = first.addAll(key.toCharArray()).addAll(last);
      } else {
        // overwrite at cursor position, remove first element from last part
        _editData = first.addAll(key.toCharArray()).addAll(last.slice(1, null));
      }
    }
    _cursorPos = _cursorPos + 1;
  }
  // delete = cursor stays same, remove from right
  hidden function removeKey(isDelete as Boolean) as Void {
    if (_editData.size() == 0) {
      return;
    }

    var first = _editData.slice(0, _cursorPos);
    var last = _editData.slice(_cursorPos, null);
    if (isDelete) {
      if (last.size() > 0) {
        _editData = first.addAll(last.slice(1, null));
      }
    } else {
      if (first.size() > 0) {
        _editData = first.slice(0, -1).addAll(last);
      } else {
        _editData = last;
      }
      _cursorPos = _cursorPos - 1;
    }
  }

  //  function setClickType(clickType as WatchUi.ClickType) as Void {
  //   _clickType = clickType;
  // }

  function getKeyPressed(coord as Lang.Array<Lang.Number>) as String {
    var x = coord[0] as Number;
    var y = coord[1] as Number;
    // Double try/catch fix for bug Value may not be initialized.
    try {
      for (var idxKey = 0; idxKey < _keyCoord.size(); idxKey++) {
        var range = _keyCoord[idxKey] as Lang.Array<Lang.Number>;
        if ((range[0] as Number) < x && x < (range[1] as Number) && (range[2] as Number) < y && y < range[3]) {
          return _keys[idxKey] as String;
        }
      }
    } catch (ex) {
      ex.printStackTrace();
    }
    try {
      for (var idxCtrl = 0; idxCtrl < _controlCoord.size(); idxCtrl++) {
        var range = _controlCoord[idxCtrl] as Lang.Array<Lang.Number>;
        if (
          (range[0] as Number) < x &&
          x < (range[1] as Number) &&
          (range[2] as Number) < y &&
          y < (range[3] as Number)
        ) {
          return _controls[idxCtrl] as String;
        }
      }
    } catch (ex) {
      ex.printStackTrace();
    }
    return "";
  }

  hidden function drawKeyPad(dc as Dc, yStart as Number, keys as Array<String>, controls as Array<String>) as Void {
    var y = yStart;
    var x = _margin;
    var margin = _margin;
    var width = _keyWidth;
    var halfWidth = width / 2;
    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

    _keyCoord = _keyCoord.slice(0, 0);
    _controlCoord = _controlCoord.slice(0, 0);

    // keys
    var idxKey = 0;
    for (idxKey = 0; idxKey < keys.size() && idxKey < 12; idxKey++) {
      if (idxKey > 0) {
        if (idxKey % _nrOfItemsInRow == 0) {
          x = margin;
          y = y + width;
        } else {
          x = x + width + 2 * _space;
        }
      }
      // QND
      dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
      dc.drawRectangle(x, y, width, width);
      if (keys[idxKey].equals("-")) {
        if (_negative) {
          dc.fillRectangle(x, y, width, width);
          dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        }
      }
      dc.drawRectangle(x, y, width, width);
      dc.drawText(
        x + halfWidth,
        y + halfWidth,
        Graphics.FONT_MEDIUM,
        keys[idxKey],
        Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
      );
      // }
      _keyCoord.add([x, x + width, y, y + width] as Lang.Array<Number>);
    }

    x = margin;
    y = y + width + 2;
    // control keys
    for (var idxCtrl = 0; idxCtrl < controls.size() && idxCtrl < 8; idxCtrl++) {
      if (idxCtrl > 0) {
        if (idxCtrl % _nrOfItemsInRow == 0) {
          x = margin;
          y = y + width;
        } else {
          x = x + width + 2 * _space;
        }
      }
      // QND
      dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
      dc.drawRectangle(x, y, width, width);
      if (controls[idxCtrl].equals("INS")) {
        if (_insert) {
          dc.fillRectangle(x, y, width, width);
          dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        }
      }
      dc.drawText(
        x + halfWidth,
        y + halfWidth,
        Graphics.FONT_MEDIUM,
        controls[idxCtrl],
        Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
      );
      _controlCoord.add([x, x + width, y, y + width] as Lang.Array<Number>);
    }
  }
}

// Implement min/max + display range (min-max) + check
class NumericOptions {
  public var minValue as Number or Float = 0;
  public var maxValue as Number or Float = 0;
  public var isFloat as Boolean = false;
  public var useMinus as Boolean = false;
  // flags @@TODO
  // public var negative as Boolean = false;

  public function initialize() {}
}

// |1~100 or |1.0~99.3 or |-1~30
function parseLabelToOptions(label as String?) as NumericOptions {
  var options = new NumericOptions();
  if (label == null) {
    return options;
  }
  var pos = label.find("|");
  if (pos == null) {
    return options;
  }
  var minmax = label.substring(pos + 1, null);
  if (minmax == null) {
    return options;
  }
  options.useMinus = minmax.find("-") != null;
  pos = minmax.find("~");
  if (pos == null) {
    options.minValue = minmax.toNumber() as Number;
  } else {
    var min = minmax.substring(null, pos);
    var max = minmax.substring(pos + 1, null);
    if (min == null || max == null) {
      return options;
    }
    if (min.find(".") != null || max.find(",") != null) {
      options.isFloat = true;
      options.minValue = min.toFloat() as Float;
      options.maxValue = max.toFloat() as Float;
    } else {
      options.minValue = min.toNumber() as Number;
      options.maxValue = max.toNumber() as Number;
    }
  }

  return options;
}
