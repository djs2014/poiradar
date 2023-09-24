import Toybox.System;
import Toybox.Lang;
using Toybox.Math;

class Point {
  var x as Lang.Number = 0;
  var y as Lang.Number = 0;
  function initialize(x as Lang.Number, y as Lang.Number) {
    self.x = x;
    self.y = y;
  }
} 

function min(a as Numeric, b as Numeric) as Numeric {
  if (a <= b) {
    return a;
  } else {
    return b;
  }
}

function max(a as Numeric, b as Numeric) as Numeric {
  if (a >= b) {
    return a;
  } else {
    return b;
  }
}

function compareTo(numberA as Numeric, numberB as Numeric) as Numeric {
  if (numberA > numberB) {
    return 1;
  } else if (numberA < numberB) {
    return -1;
  } else {
    return 0;
  }
}

function percentageOf(value as Numeric?, max as Numeric?) as Numeric {
  if (value == null || max == null) {
    return 0.0f;
  }
  if (max <= 0) {
    return 0.0f;
  }
  return value / (max / 100.0);
}

function valueOfPercentage(percentage as Numeric?, maxValue as Numeric?) as Numeric {
  if (percentage == null || maxValue == null) {
    return maxValue as Numeric;
  }
  return maxValue * (percentage / 100.0);
}

// straight line formula y = slope * x + b;
function slopeOfLine(x1 as Numeric, y1 as Numeric, x2 as Numeric, y2 as Numeric) as Numeric {
  var rise_deltaY = y2 - y1;
  var run_deltaX = x2 - x1;
  if (run_deltaX == 0.0) {
    return 0.0f;
  }
  // integer division  * 1.0
  return rise_deltaY.toFloat() / run_deltaX.toFloat();
}

function angleInDegreesBetweenXaxisAndLine(x1 as Numeric, y1 as Numeric, x2 as Numeric, y2 as Numeric) as Numeric {
  var angleRadians = Math.atan2(y2 - y1, x2 - x1);
  return rad2deg(angleRadians);
}

function intersect(
  x1 as Number,
  y1 as Number,
  x2 as Number,
  y2 as Number,
  x3 as Number,
  y3 as Number,
  x4 as Number,
  y4 as Number
) as Point? {
  var tB = (x1 - x2) * (y3 - y4) - (y1 - y2) * (x3 - x4);
  if (tB == 0) {
    return null;
  }
  var tA = (x1 - x3) * (y3 - y4) - (y1 - y3) * (x3 - x4);
  var t = tA / tB.toDouble();
  if (t < 0 || t > 1) {
    return null;
  }

  var uB = (x1 - x2) * (y3 - y4) - (y1 - y2) * (x3 - x4);
  if (uB == 0) {
    return null;
  }
  var uA = (x1 - x3) * (y1 - y2) - (y1 - y3) * (x1 - x2);
  var u = uA / uB.toDouble();
  if (u < 0 || u > 1) {
    return null;
  }

  return new Point((x1 + t * (x2 - x1)).toNumber(), (y1 + t * (y2 - y1)).toNumber());
}
