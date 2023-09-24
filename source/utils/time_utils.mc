import Toybox.Time;
import Toybox.Application;
import Toybox.System;
import Toybox.Lang;
import Toybox.Time.Gregorian;

typedef TimeValue as Number or Time.Moment;

function isDelayedFor(timeValue as TimeValue?, minutesDelayed as Number) as Boolean {
  //! True if timevalue is later than now + minutesDelayed
  if (timeValue == null || minutesDelayed <= 0) {
    return false;
  }

  if (timeValue instanceof Lang.Number) {
    return Time.now().value() - timeValue > minutesDelayed * 60;
  } else if (timeValue instanceof Time.Moment) {
    return Time.now().compare(timeValue) > minutesDelayed * 60;
  }

  return false;
}

function getMinutesDelayed(timeValue as TimeValue?) as Number {
  var differenceInSeconds = 0;
  if (timeValue == null) {
    return differenceInSeconds;
  }

  if (timeValue instanceof Lang.Number) {
    differenceInSeconds = Time.now().value() - timeValue;
  } else if (timeValue instanceof Time.Moment) {
    differenceInSeconds = Time.now().value() - (timeValue as Time.Moment).value();
  }

  if (differenceInSeconds <= 0) {
    return 0;
  }
  return differenceInSeconds / 60;
}

function ensureXSecondsPassed(previousMomentInSeconds as Number, seconds as Number) as Boolean {
  if (previousMomentInSeconds == null || previousMomentInSeconds <= 0) {
    return true;
  }
  var diff = Time.now().value() - previousMomentInSeconds;
  System.println("ensureXSecondsPassed difference: " + diff);
  return diff >= seconds;
}

function getDateTimeString(moment as Time.Moment?) as String {
  if (moment != null && moment instanceof Time.Moment) {
    var start = Gregorian.info(moment, Time.FORMAT_SHORT);
    return Lang.format("$1$-$2$-$3$ $4$:$5$:$6$", [
      start.year,
      start.month,
      start.day,
      start.hour.format("%02d"),
      start.min.format("%02d"),
      start.sec.format("%02d"),
    ]);
  }
  return "";
}

function getTimeString(moment as Time.Moment?) as String {
  if (moment != null && moment instanceof Time.Moment) {
    var date = Gregorian.info(moment, Time.FORMAT_SHORT);
    return date.hour.format("%02d") + ":" + date.min.format("%02d") + ":" + date.sec.format("%02d");
  }
  return "";
}

function getShortTimeString(moment as Time.Moment?) as String {
  if (moment != null && moment instanceof Time.Moment) {
    var date = Gregorian.info(moment, Time.FORMAT_SHORT);
    return date.hour.format("%02d") + ":" + date.min.format("%02d");
  }
  return "";
}

// template: "{h}:{m}:{s}:{ms}"
function millisecondsToShortTimeString(totalMilliSeconds as Number, template as String) as String {
  if (totalMilliSeconds != null && totalMilliSeconds instanceof Lang.Number) {
    var hours = (totalMilliSeconds / (1000.0 * 60 * 60)).toNumber() % 24;
    var minutes = (totalMilliSeconds / (1000.0 * 60.0)).toNumber() % 60;
    var seconds = (totalMilliSeconds / 1000.0).toNumber() % 60;
    var mseconds = totalMilliSeconds.toNumber() % 1000;

    if (template.length() == 0) {
      template = "{h}:{m}:{s}:{ms}";
    }
    var time = stringReplace(template, "{h}", hours.format("%01d"));
    time = stringReplace(time, "{m}", minutes.format("%02d"));
    time = stringReplace(time, "{s}", seconds.format("%02d"));
    time = stringReplace(time, "{ms}", mseconds.format("%03d"));

    return time;
  }
  return "";
}
// template: "{h}:{m}:{s}"
function secondsToShortTimeString(totalSeconds as Number, template as String) as String {
  if (totalSeconds != null && totalSeconds instanceof Lang.Number) {
    var hours = (totalSeconds / (60 * 60)).toNumber() % 24;
    var minutes = (totalSeconds / 60.0).toNumber() % 60;
    var seconds = totalSeconds.toNumber() % 60;

    if (template.length() == 0) {
      template = "{h}:{m}:{s}";
    }
    var time = stringReplace(template, "{h}", hours.format("%01d"));
    time = stringReplace(time, "{m}", minutes.format("%02d"));
    time = stringReplace(time, "{s}", seconds.format("%02d"));

    return time;
  }
  return "";
}

// 1:40 or 150:40
function secondsToCompactTimeString(totalSeconds as Number, template as String) as String {
  if (totalSeconds != null && totalSeconds instanceof Lang.Number) {
    var minutes = (totalSeconds / 60.0).toNumber();
    var seconds = totalSeconds.toNumber() % 60;

    if (template.length() == 0) {
      template = "{h}:{m}:{s}";
    }
    var time = stringReplace(template, "{m}", minutes.format("%01d"));
    time = stringReplace(time, "{s}", seconds.format("%02d"));

    return time;
  }
  return "";
}
