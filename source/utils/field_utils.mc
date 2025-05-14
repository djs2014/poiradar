import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;

enum EdgeField {
  EfSmall = 0, // half width
  EfWide = 1, // full width, height < 120
  EfLarge = 2, // full width, height >= 120 < 200
  EfOne = 3, // full screen
}

var EdgeVersion as Number = 0;

function getEdgeVersion() as Number {
  if ($.EdgeVersion > 0) {
    return $.EdgeVersion;
  }
  var settings = System.getDeviceSettings();

  if (settings.screenWidth >= 480 && settings.screenHeight >= 800) {
    $.EdgeVersion = 1050;
    return $.EdgeVersion;
  }

  if (settings.screenWidth >= 282 && settings.screenHeight >= 470) {
    $.EdgeVersion = 1040; // or 1030
    return $.EdgeVersion;
  }

  $.EdgeVersion = 840; // or 830
  return $.EdgeVersion;
}

// For edge <= 1040
function getEdgeField(dc as Dc) as EdgeField {
  var height = dc.getHeight();
  var width = dc.getWidth();

  var edge = $.getEdgeVersion();
  var ef;
  if (edge < 1050) {
    if (width < 150) {
      ef = EfSmall;
    } else {
      if (height < 120) {
        ef = EfWide;
      } else if (height > 234) {
        ef = EfOne;
      } else {
        ef = EfLarge;
      }
    }
  } else {
    if (width < 250) {
      ef = EfSmall;
    } else {
      if (height < 266) {
        ef = EfWide;
      } else if (height > 400) {
        ef = EfOne;
      } else {
        ef = EfLarge;
      }
    }
  }
  return ef;
}

function getEdgeFieldText(ef as EdgeField) as String {
  switch (ef) {
    case EfSmall:
      return "small";
    case EfWide:
      return "wide";
    case EfLarge:
      return "large";
    case EfOne:
      return "one";
  }
  return "?";
}
