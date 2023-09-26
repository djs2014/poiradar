import Toybox.System;
import Toybox.Lang;
import Toybox.Math;
import Toybox.Graphics;
import Toybox.Application;

var gCreateColors as Boolean = false;
var gUseSetFillStroke as Boolean = false;

function checkFeatures() as Void {
  $.gCreateColors = Graphics has : createColor;
  try {
    $.gUseSetFillStroke = Graphics.Dc has : setStroke;
    if ($.gUseSetFillStroke) {
      $.gUseSetFillStroke = Graphics.Dc has : setFill;
    }
  } catch (ex) {
    ex.printStackTrace();
  }
}

// [perc, R, G, B]
const PERC_COLORS_SCHEME_DIST =
  [
    [0, 0, 0, 0], // Black
    [100, 170, 170, 170],    // COLOR_LT_GRAY 
  ] as Array<Array<Number> >;

// alpha, 255 is solid, 0 is transparent
function percentageToColorAlt(
  percentage as Numeric?,
  alpha as Number,
  colorScheme as Array<Array<Number> >,
  darker as Number
) as ColorType {
  var pcolor = 0;
  var pColors = colorScheme;
  if (percentage == null || percentage == 0) {
    return Graphics.createColor(alpha, 255, 255, 255); //@@get from scheme
  }
  // else if (percentage >= 100) {
  //   // final entry
  //   pcolor = pColors[pColors.size() - 1] as Array<Number>;
  //   return Graphics.createColor(alpha, pcolor[1], pcolor[2], pcolor[3]);
  // }

  var i = 1;
  while (i < pColors.size()) {
    pcolor = pColors[i] as Array<Number>;
    if (percentage <= pcolor[0]) {
      break;
    }
    i++;
  }
  if (i >= pColors.size()) {
    i = pColors.size() - 1;
  }

  // System.println(percentage);
  // System.println(i);

  var lower = pColors[i - 1];
  var upper = pColors[i];
  var range = upper[0] - lower[0];
  var rangePct = 1;
  if (range != 0) {
    rangePct = (percentage - lower[0]) / range;
  }
  var pctLower = 1 - rangePct;
  var pctUpper = rangePct;

  var red = Math.floor(lower[1] * pctLower + upper[1] * pctUpper);
  var green = Math.floor(lower[2] * pctLower + upper[2] * pctUpper);
  var blue = Math.floor(lower[3] * pctLower + upper[3] * pctUpper);

  if (darker > 0 && darker < 100) {
    red = red - (red / 100) * darker;
    green = green - (green / 100) * darker;
    blue = blue - (blue / 100) * darker;
  }

  return Graphics.createColor(alpha, red.toNumber(), green.toNumber(), blue.toNumber());
}