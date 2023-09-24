import Toybox.Activity;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Math;
import Toybox.Attention;
using Toybox.Position;

class poiradarView extends WatchUi.DataField {
  var mBGServiceHandler as BGServiceHandler;
  var mAlertHandler as AlertHandler;
  var mCurrentLocation as CurrentLocation = new CurrentLocation();

  var mLargeField as Boolean = false;
  var mSmallField as Boolean = false;
  var mWideField as Boolean = false;
  var mTinyField as Boolean = false;
  var mHeight as Number = 0;
  var mWidth as Number = 0;
  var mFlashScreen as Boolean = false;

  hidden var mLineColor as Graphics.ColorType = Graphics.COLOR_BLACK;
  hidden var mLongLineColor as Graphics.ColorType = Graphics.COLOR_LT_GRAY;
  hidden var mFontColor as Graphics.ColorType = Graphics.COLOR_DK_GRAY;
  hidden var mTargetColor as Graphics.ColorType = Graphics.COLOR_BLUE;

  hidden var previousTrack as Float = 0.0f;
  hidden var track as Number = 0;

  hidden var mWpts as Array<WayPoint> = [] as Array<WayPoint>;
  hidden var mPoiSet as String = "";
  hidden var mCurWpt as WayPoint = new WayPoint(0.0d, 0.0d);
  hidden var mDc as Dc?;

  // Stats
  hidden var mZoomRange as Double = 0.0d;
  hidden var mWptCount as Number = 0;
  hidden var mMinDistanceMeters as Float = 0.0f;
  hidden var mMaxDistanceMeters as Float = 0.0f;
  hidden var mCloseRangeList as Array<String> = [] as Array<String>;

  function initialize() {
    DataField.initialize();

    mCurrentLocation.setOnLocationChanged(self, :onLocationChanged);
    mBGServiceHandler = getApp().getBGServiceHandler();
    mBGServiceHandler.setOnBackgroundData(self, :onBackgroundData);
    mBGServiceHandler.setCurrentLocation(mCurrentLocation);
    mAlertHandler = getApp().getAlertHandler();

    // @@ set testset
    // var curWpt = new WayPoint(52.25309763068757d, 4.869143058934727d);
    // var wpt = new WayPoint(52.26357988134586d, 4.863469746018189d);
    // wpt.name = "N";
    // mWpts.add(wpt);
    // wpt = new WayPoint(52.24994604031605d, 4.880909930169028d);
    // wpt.name = "E";
    // mWpts.add(wpt);

    // wpt = new WayPoint(52.23984657942435d, 4.864940604922476d);
    // wpt.name = "S";
    // mWpts.add(wpt);

    // wpt = new WayPoint(52.25091083665867d, 4.843508089459999d);
    // wpt.name = "W";
    // mWpts.add(wpt);

    // wpt = new WayPoint(52.211221473859155, 4.72525498202701);
    // wpt.name = "S far";
    // mWpts.add(wpt);
  }

  function onLayout(dc as Dc) as Void {
    mDc = dc;
    mHeight = dc.getHeight();
    mWidth = dc.getWidth();
    mLargeField = false;
    mWideField = mWidth > 200;
    if (mHeight <= 100) {
      //  mFontText = Graphics.FONT_XTINY;
      mSmallField = true;
    } else {
      //  mFontText = Graphics.FONT_SMALL;
      mSmallField = false;
      mLargeField = mHeight > 300;
    }
    mTinyField = mSmallField && !mWideField;

    // large field -> bigger zoom possible

    calculateOptimalZoom(dc);
  }

  function compute(info as Activity.Info) as Void {
    try {
      // if ($.gDebug) {
      //   track = (track + 10) % 360;
      // } else {
      track = getBearing(info as Activity.Info?);
      // }
      //if (info has :timerState && info.timerState != null) { mTimerState = info.timerState as Lang.Number; }
      // get cached location
      mBGServiceHandler.onCompute(info);
      mBGServiceHandler.autoScheduleService();

      // get cached wpts
    } catch (ex) {
      ex.printStackTrace();
    }

    // onBackground - get wpts, cache wpts

    // processAlerts
    // stats: #wpts, min distance, #encountered
  }

  function onBackgroundData(data as Dictionary) as Void {
    $._bgData = $.toPoiData(data);
    var poiData = $._bgData as PoiData;
    if (poiData.set.length() > 0) {
      mWpts = poiData.pts;
      mPoiSet = poiData.set;
    }

    if (mDc != null) {
      calculateOptimalZoom(mDc as Dc);
    }

    // bgHandler.setLastObservationMoment(bgData.getObservationTime());
  }

  function onLocationChanged() as Void {
    var degrees = mCurrentLocation.getCurrentDegrees();
    mCurWpt = new WayPoint(degrees[0], degrees[1]);

    if (mDc != null) {
      calculateOptimalZoom(mDc as Dc);
    }
  }

  // @@ + setting autozoom yes/no
  function calculateOptimalZoom(dc as Dc) as Void {
    if (!mCurrentLocation.hasLocation()) {
      return;
    }
    var lat = mCurWpt.lat;
    var lon = mCurWpt.lon;

    calculatePoiStats(lat, lon);
    if (mWptCount == 0) {
      return;
    }

    var fixedRange = $.g_sf_FixedRangeInMeter;
    var extraRange = $.g_sf_ExtraRangeInMeter;
    if (mLargeField) {
      extraRange = $.g_lf_ExtraRangeInMeter;
      fixedRange = $.g_lf_FixedRangeInMeter;
    } else if (mTinyField) {
      extraRange = $.g_tf_ExtraRangeInMeter;
      fixedRange = $.g_tf_FixedRangeInMeter;
    }
    var wptClosest;
    if (fixedRange) {
      wptClosest = getWayPointByDistanceAndHeading(lat, lon, 90d, fixedRange / 1000.0d);
    } else {
      wptClosest = getWayPointByDistanceAndHeading(lat, lon, 90d, (mMinDistanceMeters + extraRange) / 1000.0d);
    }

    mZoomRange = lon - wptClosest.lon;
    if (mZoomRange < 0.0d) {
      mZoomRange = mZoomRange * -1.0;
    }

    System.println(
      Lang.format("Calculated: #wpts[$1$] distance min[$2$] max[$2$] zoom range[$3$]", [
        mWptCount,
        mMinDistanceMeters,
        mMaxDistanceMeters,
        mZoomRange,
      ])
    );
  }

  function onUpdate(dc as Dc) as Void {
    dc.setColor(getBackgroundColor(), getBackgroundColor());
    dc.clear();

    // @@ test valid location

    if (mFlashScreen) {
      dc.setColor(Graphics.COLOR_TRANSPARENT, Graphics.COLOR_YELLOW);
      dc.clear();
      mFlashScreen = false;
    }
    var mFontWptLabel = Graphics.FONT_XTINY;
    var showDistance = $.g_sf_ShowWptDistance;
    var showDirection = $.g_sf_ShowWptDirection;
    var showCircleDistance = $.g_sf_ShowCircleDistance;
    if (mLargeField) {
      showDistance = $.g_lf_ShowWptDistance;
      showDirection = $.g_lf_ShowWptDirection;
      showCircleDistance = $.g_lf_ShowCircleDistance;
      mFontWptLabel = Graphics.FONT_TINY;
    } else if (mTinyField) {
      showDistance = $.g_tf_ShowWptDistance;
      showDirection = $.g_tf_ShowWptDirection;
      showCircleDistance = $.g_tf_ShowCircleDistance;
    }
    mLineColor = Graphics.COLOR_BLACK;
    if (getBackgroundColor() == Graphics.COLOR_BLACK) {
      mLineColor = Graphics.COLOR_WHITE;
      mFontColor = Graphics.COLOR_LT_GRAY;
    } else {
      mLineColor = Graphics.COLOR_BLACK;
      mFontColor = Graphics.COLOR_DK_GRAY;
    }

    dc.setColor(mFontColor, Graphics.COLOR_TRANSPARENT);
    var statsProxy = "";
    if (mTinyField) {
      statsProxy = mCurrentLocation.infoLocation();
    } else {
      statsProxy = mCurrentLocation.infoLocation() + " " + mCurrentLocation.infoAccuracy();
    }
    dc.drawText(0, 0, Graphics.FONT_XTINY, statsProxy, Graphics.TEXT_JUSTIFY_LEFT);
    if (!mTinyField) {
      dc.drawText(mWidth, 0, Graphics.FONT_XTINY, mPoiSet, Graphics.TEXT_JUSTIFY_RIGHT);
      if ($.g_alert_closeRangeMeters > 0) {
        var statsTravel = "Found " + mCloseRangeList.size().format("%d");
        var statsTravelWH = dc.getTextDimensions(statsTravel, Graphics.FONT_XTINY);
        dc.drawText(mWidth, statsTravelWH[1], Graphics.FONT_XTINY, statsTravel, Graphics.TEXT_JUSTIFY_RIGHT);
      }
    }

    var w = mWidth;
    var h = mHeight;
    var x1 = mWidth / 2;
    var y1 = mHeight / 2;

    dc.setColor(Graphics.COLOR_DK_BLUE, Graphics.COLOR_TRANSPARENT);
    dc.drawText(w / 2, 0, Graphics.FONT_SMALL, $.getCompassDirection(track), Graphics.TEXT_JUSTIFY_CENTER);
    // dc.drawText(w / 2, 12, Graphics.FONT_SMALL, track.format("%d"), Graphics.TEXT_JUSTIFY_CENTER);
    // $.getCompassDirection( @@ check right directions

    var lat = mCurWpt.lat;
    var lon = mCurWpt.lon;

    // @@ auto set center point to bottom when zoomed.. and/or small field
    y1 = (y1 + y1 / 2).toNumber();
    // @@ draw closed with thick line
    // @@ get stats: #pts in range, distance , heading

    var mapLonRight = lon - mZoomRange;
    var mapLonLeft = lon + mZoomRange;
    var mapLatBottom = lat;

    System.println(
      Lang.format("Stats #wpts[$1$] distance min[$2$] max[$2$] zoom range[$3$]", [
        mWptCount,
        mMinDistanceMeters,
        mMaxDistanceMeters,
        mZoomRange,
      ])
    );

    var wptKm1 = getWayPointByDistanceAndHeading(lat, lon, 90d, 1d);
    var ptkm1 = convertGeoToPixel(wptKm1.lat, wptKm1.lon, w, h, mapLonRight, mapLonLeft, mapLatBottom);

    var radius_km1 = ptkm1.x - x1;
    if (radius_km1 < 0) {
      radius_km1 = radius_km1 * -1.0;
    }

    if ($.g_alert_closeRangeMeters > 0) {
      dc.setColor(Graphics.COLOR_ORANGE, Graphics.COLOR_TRANSPARENT);
      dc.drawCircle(x1, y1, radius_km1 * ($.g_alert_closeRangeMeters / 1000.0f));
    }

    // draw 1 km circle, then per 1km and after 5km per 5km increase.
    dc.setColor(Graphics.COLOR_DK_GREEN, Graphics.COLOR_TRANSPARENT);
    dc.drawCircle(x1, y1, radius_km1);
    if (showCircleDistance) {
      dc.drawText(
        x1 + radius_km1 - 2,
        y1,
        Graphics.FONT_TINY,
        "1",
        Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
      );
    }
    var ccount = 1;
    var circle_km = 2;
    var cradius = radius_km1 * circle_km;
    while (ccount < 10 && cradius * 2 < mWidth) {
      dc.drawCircle(x1, y1, cradius);
      if (showCircleDistance) {
        dc.drawText(
          x1 + cradius - 2,
          y1,
          Graphics.FONT_TINY,
          circle_km.format("%d"),
          Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
      }

      if (circle_km == 5) {
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        circle_km = 10;
      } else if (circle_km > 5) {
        circle_km = circle_km + 5;
      } else {
        circle_km++;
      }
      cradius = radius_km1 * circle_km;
      ccount++;
    }

    if ($.gDebug) {
      var r = 0;
      while (r < 360) {
        var ptest = getPointOnCircle(x1, y1, r, radius_km1);
        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(x1, y1, ptest.x, ptest.y);
        dc.drawText(ptest.x, ptest.y, Graphics.FONT_SMALL, r.format("%d"), Graphics.TEXT_JUSTIFY_CENTER);
        r = r + 45;
      }
    }

    // if (!mCurrentLocation.hasLocation()) {
    //       return;
    //     }

    for (var i = 0; i < mWpts.size(); i++) {
      var wpt = mWpts[i];

      var distanceKm = $.getDistanceFromLatLonInKm(lat, lon, wpt.lat, wpt.lon);
      var bearing = $.getRhumbLineBearing(lat, lon, wpt.lat, wpt.lon);

      if ($.gDebug) {
        System.println(
          Lang.format("orig from[$1$,$2$] to[$3$,$4$] bearing[$5$]($6$) distanceKm[$7$]", [
            lat,
            lon,
            wpt.lat,
            wpt.lon,
            bearing,
            $.getCompassDirection(bearing),
            distanceKm,
          ])
        );
      }

      // auto rotate point for display, actual bearing to the point stays the same (ie ENE stays ENE from current point!)
      // display is relative to top of the edge device
      var wptBearing = bearing - track;
      if ($.gDebug) {
        System.println(
          Lang.format("autorotate from[$1$,$2$] to[$3$,$4$] wptBearing[$5$]($6$) distanceKm[$7$]", [
            lat,
            lon,
            wpt.lat,
            wpt.lon,
            wptBearing,
            $.getCompassDirection(bearing),
            distanceKm,
          ])
        );
      }

      var pt = getBearingPointOnCircle(x1, y1, wptBearing, distanceKm * radius_km1);
      var text = "";
      var distanceMeters = distanceKm * 1000.0f;
      if (showDistance) {
        text =
          getDistanceInMeterOrKm(distanceMeters).format(getFormatForMeterAndKm(distanceMeters)) +
          " " +
          getUnitsInMeterOrKm(distanceMeters);
      }
      if (showDirection) {
        text = text + "(" + $.getCompassDirection(bearing) + ")";
      }

      var px = pt.x;
      var py = pt.y;
      var targetVisible = true;
      // points outside the screen -> draw only until the border
      if (px < 0 || px > w || py < 0 || py > h) {
        // https://en.wikipedia.org/wiki/Line%E2%80%93line_intersection#Given_two_points_on_each_line_segment
        // calc t and u for top border, right border, bottom border and left border with wpt
        // intersect with top border
        var pInter = intersect(0, 0, w, 0, x1, y1, px, py);
        if (pInter == null) {
          // right
          pInter = intersect(w, 0, w, h, x1, y1, px, py);
          if (pInter == null) {
            // bottom
            pInter = intersect(0, h, w, h, x1, y1, px, py);
            if (pInter == null) {
              // left
              pInter = intersect(0, 0, 0, h, x1, y1, px, py);
            }
          }
        }
        if (pInter != null) {
          px = pInter.x;
          py = pInter.y;
          targetVisible = false;
        }
      }

      if (targetVisible || distanceKm <= mMinDistanceMeters / 1000.0) {
        dc.setColor(mLineColor, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        dc.drawLine(x1, y1, px, py);
        dc.setPenWidth(1);
        if (text.length() > 0) {
          dc.setColor(mFontColor, Graphics.COLOR_TRANSPARENT);
          dc.drawText(px, py, mFontWptLabel, text, Graphics.TEXT_JUSTIFY_CENTER);
        }

        dc.setColor(mTargetColor, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(px, py, 5);
      } else {
        dc.setColor(mLongLineColor, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(x1, y1, px, py);
      }
    }

    // Draw #wpts, min, max @@
    dc.setColor(mFontColor, Graphics.COLOR_TRANSPARENT);

    var statsWpts = "";
    if (mTinyField) {
      statsWpts =
        "min " +
        getDistanceInMeterOrKm(mMinDistanceMeters).format(getFormatForMeterAndKm(mMinDistanceMeters)) +
        " " +
        getUnitsInMeterOrKm(mMinDistanceMeters);
    } else {
      statsWpts = "#" + mWptCount.format("%d");
      statsWpts =
        statsWpts +
        " min " +
        getDistanceInMeterOrKm(mMinDistanceMeters).format(getFormatForMeterAndKm(mMinDistanceMeters)) +
        " " +
        getUnitsInMeterOrKm(mMinDistanceMeters);
    }
    var statsWptsWH = dc.getTextDimensions(statsWpts, Graphics.FONT_XTINY);
    dc.drawText(0, mHeight - statsWptsWH[1], Graphics.FONT_XTINY, statsWpts, Graphics.TEXT_JUSTIFY_LEFT);

    // Draw stats

    var stats = "";
    if (mTinyField) {
      stats = "#" + mBGServiceHandler.getCounterStats();
    } else {
      var counter = "#" + mBGServiceHandler.getCounterStats();
      var next = mBGServiceHandler.getWhenNextRequest("");
      var status = "";
      if (mBGServiceHandler.hasError()) {
        status = mBGServiceHandler.getError();
      } else {
        status = mBGServiceHandler.getStatus();
      }
      stats = mBGServiceHandler.getErrorMessage() + " " + counter + " " + status + "(" + next + ")";
    }

    var statsWH = dc.getTextDimensions(stats, Graphics.FONT_XTINY);
    dc.drawText(mWidth, mHeight - statsWH[1], Graphics.FONT_XTINY, stats, Graphics.TEXT_JUSTIFY_RIGHT);
  }

  function calculatePoiStats(lat as Double, lon as Double) as Void {
    var count = mWpts.size();
    var numberInCloseRange = 0;

    var wptsNeeded = $.g_sf_ZoomMinWayPoints;
    var zoomOnOneMeters = $.g_sf_zoomOneMeters;
    if (mLargeField) {
      wptsNeeded = $.g_lf_ZoomMinWayPoints;
      zoomOnOneMeters = $.g_lf_zoomOneMeters;
    } else if (mTinyField) {
      wptsNeeded = $.g_tf_ZoomMinWayPoints;
      zoomOnOneMeters = $.g_tf_zoomOneMeters;
    }

    var sorted = [] as Array<Float>;
    var min = 0.0f;
    var max = 0.0f;
    for (var i = 0; i < count; i++) {
      var wpt = mWpts[i];
      var distanceMeters = $.getDistanceFromLatLonInKm(lat, lon, wpt.lat, wpt.lon) * 1000.0f;
      if (max == 0.0f || distanceMeters > max) {
        max = distanceMeters;
      }
      if (min == 0.0f || distanceMeters < min) {
        min = distanceMeters;
      }

      if (wptsNeeded > 1) {
        // Add sorted
        var ssize = sorted.size();
        if (ssize == 0) {
          sorted.add(distanceMeters);
        } else {
          for (var idx = 0; idx < ssize; idx++) {
            if (distanceMeters > sorted[idx]) {
              sorted.add(distanceMeters);
            }
          }
        }
      }

      if ($.g_alert_closeRangeMeters > 0 && distanceMeters < $.g_alert_closeRangeMeters) {
        numberInCloseRange = numberInCloseRange + processCloseRange(wpt);
      }
    }

    mWptCount = count;
    mMinDistanceMeters = min;
    if (min > zoomOnOneMeters && wptsNeeded > 1 && wptsNeeded < sorted.size()) {
      // Include the needed wpts by minimal distance
      mMinDistanceMeters = sorted[wptsNeeded];
    }
    mMaxDistanceMeters = max;
    System.println(
      Lang.format("Poi Stats #wpts[$1$] distance min[$2$]meter max[$2$]meter newInCloseRange[$3$]", [
        mWptCount,
        mMinDistanceMeters,
        mMaxDistanceMeters,
        numberInCloseRange,
      ])
    );

    if ($.g_alert_closeRange && numberInCloseRange > 0) {
      // @@ Handle only when visible
      mFlashScreen = true;
      if (Attention has :ToneProfile) {
        var toneProfile =
          [
            new Attention.ToneProfile(1000, 40),
            new Attention.ToneProfile(1500, 100),
            new Attention.ToneProfile(3000, 0),
          ] as Lang.Array<Attention.ToneProfile>;
        Attention.playTone({ :toneProfile => toneProfile, :repeatCount => numberInCloseRange });
      }
    }
  }

  function processCloseRange(wpt as WayPoint) as Number {
    var key = Lang.format("$1$|$2$", [wpt.lon, wpt.lat]);
    var idx = mCloseRangeList.indexOf(key);
    if (idx < 0) {
      mCloseRangeList.add(key);
      return 1;
    }
    return 0;
  }

  function getBearing(a_info as Activity.Info?) as Number {
    var track = getActivityValue(a_info, :track, 0.0f) as Float;
    if (track == 0.0f) {
      track = getActivityValue(a_info, :currentHeading, 0.0f) as Float;
    }
    if (track == 0.0f) {
      track = previousTrack;
    } else {
      previousTrack = track;
    }
    return $.rad2deg(track).toNumber();
  }
}
