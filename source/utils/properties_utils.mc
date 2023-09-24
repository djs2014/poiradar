import Toybox.Lang;
import Toybox.Application;
import Toybox.System;
import Toybox.Application.Storage;
import Toybox.Activity;
import Toybox.Application.Properties;

function getApplicationProperty(
  key as Application.PropertyKeyType,
  dflt as Application.PropertyValueType
) as Application.PropertyValueType {
 try {
    var val = Properties.getValue(key);
    if (val != null) {
      return val;
    }
  } catch (e) {
    return dflt;
  }
  return dflt;
}

function getDictionaryValue(data as Dictionary, key as String, defaultValue as Object?) as Object? {
  var value = data.get(key);
  if (value == null) {
    return defaultValue;
  }
  return value as Numeric;
}

function getActivityValue(info as Activity.Info?, symbol as Symbol, dflt as Lang.Object) as Lang.Object {
  if (info == null) {
    return dflt;
  }
  var ainfo = info as Activity.Info;

  if (ainfo has symbol) {
    if (ainfo[symbol] != null) {
      return ainfo[symbol] as Lang.Object;
    }
  }
  return dflt;
}

function getStorageValue(
  key as Application.PropertyKeyType,
  dflt as Application.PropertyValueType
) as Application.PropertyValueType {
  try {
    var val = Toybox.Application.Storage.getValue(key);
    if (val != null) {
      return val;
    }
  } catch (e) {
    return dflt;
  }
  return dflt;
}

function getNumericValue(value as Numeric?, def as Numeric?) as Numeric? {
  if (value == null) {
    return def;
  }
  return value;
}

function getStringValue(value as String?, def as String?) as String? {
  if (value == null) {
    return def;
  }
  return value;
}
