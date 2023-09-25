import Toybox.System;
import Toybox.Lang;

function stringReplace(str as String, oldString as String, newString as String) as String {
  var result = str;
  //if (str == null || oldString == null || newString == null) {
  //  return str;
  //}

  var index = result.find(oldString);
  var count = 0;
  while (index != null && count < 30) {
    var indexEnd = index + oldString.length();
    result = result.substring(0, index) + newString + result.substring(indexEnd, result.length());
    index = result.find(oldString);
    count = count + 1;
  }

  return result;
}

function stringReplacePos(
  str as String,
  start as Number,
  oldString as String,
  newString as String,
  occurrence as Number
) as String {
  var result = str;
  //if (str == null || oldString == null || newString == null) {
  //  return str;
  //}

  if (start > str.length()) {
    return str;
  }

  var pre = str.substring(0, start) as String;
  result = str.substring(start, str.length()) as String;

  var index = result.find(oldString);
  var count = 0;
  while (index != null && count < occurrence) {
    var indexEnd = index + oldString.length();
    result = result.substring(0, index) + newString + result.substring(indexEnd, result.length());
    index = result.find(oldString);
    count = count + 1;
  }

  return pre + result;
}
