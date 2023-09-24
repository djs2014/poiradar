import Toybox.Lang;
import Toybox.System;

/*
Alert when in range per lat,lon
Alert when close by per lat, lon
*/
// enum ActiveAlert {
//   aaUvi,
//   aaRain1stHour,
//   aaPrecChance,
//   aaWind,
//   aaCondition
// }

class AlertHandler {
  hidden var alertUvi as Lang.Number = 0;
  hidden var alertPrecipitationChance as Lang.Number = 0;
  hidden var alertRainMMfirstHour as Lang.Number = 0;
  hidden var alertWindSpeed as Lang.Number = 0;
  hidden var alertDewpoint as Lang.Number = 0;

  var maxUvi as Lang.Float = 0.0;
  var maxPrecipitationChance as Lang.Number = 0;
  var maxRainMMfirstHour as Lang.Number = 0;
  var maxWindSpeed as Lang.Float = 0.0;
  var maxDewpoint as Lang.Float = 0.0;

  hidden var CONDITION_NEUTRAL as Lang.Number = 0x00aaff; // COLOR_BLUE

  hidden const NEUTRAL = 0;
  hidden const TRIGGERED = 1;
  hidden const HANDLED = 2;

  hidden var statusUvi as Lang.Number = NEUTRAL;
  hidden var statusPrecipitationChance as Lang.Number = NEUTRAL;
  hidden var statusRainMMfirstHour as Lang.Number = NEUTRAL;
  hidden var statusCondition as Lang.Number = NEUTRAL;
  hidden var statusWindSpeed as Lang.Number = NEUTRAL;
  hidden var statusDewpoint as Lang.Number = NEUTRAL;

  hidden var allClearUvi as Lang.Boolean = true;
  hidden var allClearPrecipitationChance as Lang.Boolean = true;
  hidden var allClearRainMMfirstHour as Lang.Boolean = true;
  hidden var allClearCondition as Lang.Boolean = true;
  hidden var allClearWindSpeed as Lang.Boolean = true;
  hidden var allClearDewpoint as Lang.Boolean = true;

  function setAlertPrecipitationChance(value as Lang.Number) as Void {
    alertPrecipitationChance = value;
  }
  function setAlertUVi(value as Lang.Number) as Void {
    alertUvi = value;
  }
  function setAlertRainMMfirstHour(value as Lang.Number) as Void {
    alertRainMMfirstHour = value;
  }
  //! is in beaufort
  function setAlertWindSpeed(value as Lang.Number) as Void {
    alertWindSpeed = value;
  }
  function setAlertDewpoint(value as Lang.Number) as Void {
    alertDewpoint = value;
  }

  function infoUvi() as Lang.String {
    return Lang.format("alerthandler alertUvi[$1$] statusUvi[$2$] allClearUvi[$3$]", [
      alertUvi,
      statusUvi,
      allClearUvi,
    ]);
  }

  function infoPrecipitationChance() as Lang.String {
    return Lang.format("alerthandler alertPop[$1$] statusPop[$2$] allClearPop[$3$]", [
      alertPrecipitationChance,
      statusPrecipitationChance,
      allClearPrecipitationChance,
    ]);
  }
  //! alert flow:
  //!  level reached --> alert triggered (display/play alert) --> (handled
  //!  displayed alert) --> reset when level below alert

  function isAnyAlertTriggered() as Lang.Boolean {
    return (
      statusUvi == TRIGGERED ||
      statusPrecipitationChance == TRIGGERED ||
      statusRainMMfirstHour == TRIGGERED ||
      statusCondition == TRIGGERED ||
      statusWindSpeed == TRIGGERED ||
      statusDewpoint == TRIGGERED
    );
  }

  function hasAlertsHandled() as Lang.Boolean {
    return (
      statusUvi == HANDLED ||
      statusPrecipitationChance == HANDLED ||
      statusRainMMfirstHour == HANDLED ||
      statusCondition == HANDLED ||
      statusWindSpeed == HANDLED ||
      statusDewpoint == HANDLED
    );
  }

  function infoHandledShort() as Array<String> {
    var info = [] as Array<String>;
    if (statusUvi == HANDLED) {
      info.add("Uv");
    }
    if (statusPrecipitationChance == HANDLED) {
      info.add("R%");
    }
    if (statusRainMMfirstHour == HANDLED) {
      info.add("R");
    }
    if (statusCondition == HANDLED) {
      info.add("C");
    }
    if (statusWindSpeed == HANDLED) {
      info.add("Ws");
    }
    if (statusDewpoint == HANDLED) {
      info.add("Dp");
    }
    return info;
  }

  function infoHandled() as Lang.String {
    var info = "";
    if (statusUvi == HANDLED) {
      info = info + " Uv" + maxUvi.format("%.1f");
    }
    if (statusPrecipitationChance == HANDLED) {
      info = info + " R%" + maxPrecipitationChance.format("%d");
    }
    if (statusRainMMfirstHour == HANDLED) {
      info = info + " R" + maxRainMMfirstHour.format("%d");
    }
    if (statusCondition == HANDLED) {
      info = info + " C";
    }
    if (statusWindSpeed == HANDLED) {
      var beaufort = windSpeedToBeaufort(maxWindSpeed);
      info = info + " Ws" + beaufort.format("%d");
    }
    if (statusDewpoint == HANDLED) {
      info = info + " Dp" + maxDewpoint.format("%.1f");
    }
    return info;
  }

  // function activeAlerts() as Array {
  //   var info = [];
  //   if (statusUvi == HANDLED) {
  //     info.add(aaUvi);
  //   }
  //   if (statusPrecipitationChance == HANDLED) {
  //     info.add(aaPrecChance);
  //   }
  //   if (statusRainMMfirstHour == HANDLED) {
  //     info.add(aaRain1stHour);
  //   }
  //   if (statusCondition == HANDLED) {
  //     info.add(aaCondition);
  //   }
  //   if (statusWindSpeed == HANDLED) {
  //     info.add(aaWind);
  //   }
  //   return info;
  // }

  function currentlyTriggeredHandled() as Void {
    if (statusUvi == TRIGGERED) {
      statusUvi = HANDLED;
      allClearUvi = true;
    }
    if (statusPrecipitationChance == TRIGGERED) {
      statusPrecipitationChance = HANDLED;
      allClearPrecipitationChance = true;
    }
    if (statusRainMMfirstHour == TRIGGERED) {
      statusRainMMfirstHour = HANDLED;
      allClearRainMMfirstHour = true;
    }
    if (statusCondition == TRIGGERED) {
      statusCondition = HANDLED;
      allClearCondition = true;
    }
    if (statusWindSpeed == TRIGGERED) {
      statusWindSpeed = HANDLED;
      allClearWindSpeed = true;
    }
    if (statusDewpoint == TRIGGERED) {
      statusDewpoint = HANDLED;
      allClearDewpoint = true;
    }
  }

  function resetStatus() as Void {
    statusPrecipitationChance = NEUTRAL;
    statusUvi = NEUTRAL;
    statusRainMMfirstHour = NEUTRAL;
    statusCondition = NEUTRAL;
    statusWindSpeed = NEUTRAL;
    statusDewpoint = NEUTRAL;

    maxUvi = 0.0;
    maxPrecipitationChance = 0;
    maxRainMMfirstHour = 0;
    maxWindSpeed = 0.0;
    maxDewpoint = 0.0;
  }

  function checkStatus() as Void {
    //maxPrecipitationChance = 0; ??
    if (allClearUvi) {
      statusUvi = NEUTRAL;
    }
    if (allClearPrecipitationChance) {
      statusPrecipitationChance = NEUTRAL;
    }
    if (allClearRainMMfirstHour) {
      statusRainMMfirstHour = NEUTRAL;
    }
    if (allClearCondition) {
      statusCondition = NEUTRAL;
    }
    if (allClearWindSpeed) {
      statusWindSpeed = NEUTRAL;
    }
    if (allClearDewpoint) {
      statusDewpoint = NEUTRAL;
    }
    resetAllClear();
  }

  hidden function resetAllClear() as Void {
    allClearUvi = true;
    allClearPrecipitationChance = true;
    allClearRainMMfirstHour = true;
    allClearCondition = true;
    allClearWindSpeed = true;
    allClearDewpoint = true;
  }

  function processUvi(uvi as Lang.Float?) as Void {
    if (alertUvi <= 0 || uvi == null) {
      return;
    }
    maxUvi = $.max(maxUvi, uvi) as Float;
    // level reached NEUTRAL -> TRIGGERED  (skip if already HANDLED)
    if (statusUvi == NEUTRAL && uvi >= alertUvi) {
      statusUvi = TRIGGERED;
    }

    // all clear again HANDLED -> NEUTRAL
    allClearUvi = allClearUvi && statusUvi == HANDLED && uvi < alertUvi;
  }

  function processPrecipitationChance(chance as Lang.Number?) as Void {
    if (chance == null) {
      return;
    }

    maxPrecipitationChance = $.max(maxPrecipitationChance, chance) as Number;

    if (alertPrecipitationChance <= 0) {
      return;
    }
    // level reached NEUTRAL -> TRIGGERED  (skip if already HANDLED)
    if (statusPrecipitationChance == NEUTRAL && chance >= alertPrecipitationChance) {
      statusPrecipitationChance = TRIGGERED;
    }

    // all clear again HANDLED -> NEUTRAL
    allClearPrecipitationChance =
      allClearPrecipitationChance && statusPrecipitationChance == HANDLED && chance < alertPrecipitationChance;
  }

  function processRainMMfirstHour(mm as Lang.Float?) as Void {
    if (alertRainMMfirstHour <= 0 || mm == null) {
      return;
    }

    maxRainMMfirstHour = $.max(maxRainMMfirstHour, mm) as Number;
    // level reached NEUTRAL -> TRIGGERED  (skip if already HANDLED)
    if (statusRainMMfirstHour == NEUTRAL && mm >= alertRainMMfirstHour) {
      statusRainMMfirstHour = TRIGGERED;
    }

    // all clear again HANDLED -> NEUTRAL
    allClearRainMMfirstHour = allClearRainMMfirstHour && statusRainMMfirstHour == HANDLED && mm < alertRainMMfirstHour;
  }

  function processWeather(colorValue as Lang.Number?) as Void {
    // level reached NEUTRAL -> TRIGGERED  (skip if already HANDLED)
    if (statusCondition == NEUTRAL && colorValue != CONDITION_NEUTRAL) {
      statusCondition = TRIGGERED;
    }

    // all clear again HANDLED -> NEUTRAL
    allClearCondition = allClearCondition && statusCondition == HANDLED && colorValue == CONDITION_NEUTRAL;
  }

  function processWindSpeed(windSpeedMs as Lang.Float?) as Void {
    if (alertWindSpeed <= 0 || windSpeedMs == null) {
      return;
    }
    maxWindSpeed = $.max(maxWindSpeed, windSpeedMs) as Float;
    // level reached NEUTRAL -> TRIGGERED  (skip if already HANDLED)
    var beaufort = $.windSpeedToBeaufort(windSpeedMs);
    if (statusWindSpeed == NEUTRAL && beaufort >= alertWindSpeed) {
      statusWindSpeed = TRIGGERED;
    }

    // all clear again HANDLED -> NEUTRAL
    allClearWindSpeed = allClearWindSpeed && statusWindSpeed == HANDLED && beaufort < alertWindSpeed;
  }

  function processDewpoint(dewPoint as Lang.Float?) as Void {
    if (alertDewpoint <= 0 || dewPoint == null) {
      return;
    }
    maxDewpoint = $.max(maxDewpoint, dewPoint) as Float;
    // level reached NEUTRAL -> TRIGGERED  (skip if already HANDLED)
    if (statusDewpoint == NEUTRAL && dewPoint >= alertDewpoint) {
      statusDewpoint = TRIGGERED;
    }

    // all clear again HANDLED -> NEUTRAL
    allClearDewpoint = allClearDewpoint && statusDewpoint == HANDLED && dewPoint < alertDewpoint;
  }
}
