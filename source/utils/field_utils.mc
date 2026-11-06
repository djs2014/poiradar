// 2026-09-13 Removed Edgeversion
// 2026-09-13 Detect high-resolution edge devices

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

// Better than checking for "Edge 1050" specifically:
var gHasHighResScreen = System.getDeviceSettings().screenWidth >= 480;
var gHasVectorFonts = Graphics has :getVectorFont;

// Since Garmin allows user-customizable data layouts (1-field, 2-field, 4-field, 10-field grids, split columns),
// field dimensions scale proportionally relative to the overall screen width and height.
function getEdgeField(dc as Dc) as EdgeField {
  var width = dc.getWidth();
  var height = dc.getHeight();

  var settings = System.getDeviceSettings();
  var screenW = settings.screenWidth;
  var screenH = settings.screenHeight;

  // 1. Full Screen / Single Field Layout (Occupies >= 85% of total screen height)
  if (height >= screenH * 0.85) {
    return EfOne;
  }

  // 2. Narrow / Split Column Field (Occupies <= 55% of screen width)
  if (width <= screenW * 0.55) {
    return EfSmall;
  }

  // 3. Wide Data Field (Spans full width, but low height <= 35% of screen height)
  if (height <= screenH * 0.35) {
    return EfWide;
  }

  // 4. Large Half-Screen / Block Field (Spans full width, 35% to 85% height)
  return EfLarge;
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
