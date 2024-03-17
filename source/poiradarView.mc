import Toybox.Activity;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Math;
import Toybox.Attention;
using Toybox.Position;

class poiradarView extends WatchUi.DataField {
  var mBGServiceHandler as BGServiceHandler;
  var mCurrentLocation as CurrentLocation = new CurrentLocation();

  var mLargeField as Boolean = false;
  var mSmallField as Boolean = false;
  var mWideField as Boolean = false;
  var mTinyField as Boolean = false;
  var mHeight as Number = 0;
  var mWidth as Number = 0;
  var mFlashWaypoint as Boolean = false;
  var mWptRadius as Number = 5;

  hidden var mLineColor as Graphics.ColorType = Graphics.COLOR_BLACK;
  hidden var mLongLineColor as Graphics.ColorType = Graphics.COLOR_LT_GRAY;
  hidden var mFontColor as Graphics.ColorType = Graphics.COLOR_DK_GRAY;
  hidden var mFontStatsColor as Graphics.ColorType = Graphics.COLOR_DK_GRAY;
  hidden var mTargetColor as Graphics.ColorType = Graphics.COLOR_BLUE;

  hidden var previousTrack as Float = 0.0f;
  hidden var track as Number = 0;

  hidden var mWpts as Array<WayPoint> = [] as Array<WayPoint>;
  hidden var mWptsSorted as Array<WayPoint> = [] as Array<WayPoint>;
  hidden var mPoiSet as String = "";
  hidden var mCurWpt as WayPoint = new WayPoint(0.0d, 0.0d);
  hidden var mDc as Dc?;

  // Stats
  hidden var mZoomRange as Double = 0.0d;
  hidden var mWptCount as Number = 0;
  hidden var mMinDistanceMeters as Float = 0.0f;
  hidden var mMaxDistanceMeters as Float = 0.0f;
  hidden var mCloseRangeList as Array<String> = [] as Array<String>;
  hidden var mProximityList as Array<String> = [] as Array<String>;

  function initialize() {
    DataField.initialize();

    $.checkFeatures();

    mCurrentLocation.setOnLocationChanged(self, :onLocationChanged);
    mBGServiceHandler = getApp().getBGServiceHandler();
    mBGServiceHandler.setOnBackgroundData(self, :onBackgroundData);
    mBGServiceHandler.setCurrentLocation(mCurrentLocation);

    // trigger to get optional cached location
    onLocationChanged();

    // @@TODO Only cached data for first time
    // if ($.gCacheBgData && !gCachedDataLoaded) {
    //   $._bgData = getCachedBgData();
    //   $.gCachedDataLoaded = true;
    // }

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
      // if (info has :timerState && info.timerState != null) { mTimerState =
      // info.timerState as Lang.Number; }
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
    //$._bgData = $.toPoiData(data);
    // var poiData = $._bgData as PoiData;

    var poiData = $.toPoiData(data);
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
    // fixedRange = 250;
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
    if ($.gDebug) {
      System.println(
        Lang.format("Calculated: #wpts[$1$] distance min[$2$] +extraRange[$3$] max[$4$] zoom range[$5$]", [
          mWptCount,
          mMinDistanceMeters,
          extraRange,
          mMaxDistanceMeters,
          mZoomRange,
        ])
      );
    }
  }

  function onUpdate(dc as Dc) as Void {
    if ($.gExitedMenu) {
      // fix for leaving menu, draw complete screen, large field
      dc.clearClip();
      $.gExitedMenu = false;
    }

    dc.setColor(getBackgroundColor(), getBackgroundColor());
    dc.clear();
    dc.setAntiAlias(true);

    var mFontWptLabel = Graphics.FONT_XTINY;
    var trackColor = Graphics.COLOR_BLACK;
    var km1RangeColor = Graphics.COLOR_DK_GREEN;
    var showDistance = $.g_sf_ShowWptDistance;
    var showDirection = $.g_sf_ShowWptDirection;
    var showCircleDistance = $.g_sf_ShowCircleDistance;
    var showTrack = $.g_sf_ShowTrack;
    var highContrast = $.g_sf_HighContrast;
    if (mLargeField) {
      showDistance = $.g_lf_ShowWptDistance;
      showDirection = $.g_lf_ShowWptDirection;
      showCircleDistance = $.g_lf_ShowCircleDistance;
      mFontWptLabel = Graphics.FONT_TINY;
      showTrack = $.g_lf_ShowTrack;
       highContrast = $.g_lf_HighContrast;
    } else if (mTinyField) {
      showDistance = $.g_tf_ShowWptDistance;
      showDirection = $.g_tf_ShowWptDirection;
      showCircleDistance = $.g_tf_ShowCircleDistance;
      showTrack = $.g_tf_ShowTrack;
      highContrast = $.g_tf_HighContrast;
    }
    mLineColor = Graphics.COLOR_BLACK;
    if (getBackgroundColor() == Graphics.COLOR_BLACK) {
      mLineColor = Graphics.COLOR_WHITE;
      mFontColor = Graphics.COLOR_LT_GRAY;
      if (highContrast) {
        mFontStatsColor = Graphics.COLOR_WHITE;
      } else {
        mFontStatsColor = Graphics.COLOR_LT_GRAY;
      }
      trackColor = Graphics.COLOR_WHITE;
      km1RangeColor = Graphics.COLOR_GREEN;
    } else {
      mLineColor = Graphics.COLOR_BLACK;
      mFontColor = Graphics.COLOR_DK_GRAY;
      if (highContrast) {
        mFontStatsColor = Graphics.COLOR_BLACK;
      } else {
        mFontStatsColor = Graphics.COLOR_DK_GRAY;
      }
    }

    

    dc.setColor(mFontStatsColor, Graphics.COLOR_TRANSPARENT);
    var statsWptsTop = "";
    if (mTinyField) {
      statsWptsTop =
        "< " +
        getDistanceInMeterOrKm(mMinDistanceMeters).format(getFormatForMeterAndKm(mMinDistanceMeters)) +
        " " +
        getUnitsInMeterOrKm(mMinDistanceMeters);
      dc.drawText(0, 0, Graphics.FONT_XTINY, statsWptsTop, Graphics.TEXT_JUSTIFY_LEFT);
      statsWptsTop =
        " > " +
        getDistanceInMeterOrKm(mMaxDistanceMeters).format(getFormatForMeterAndKm(mMaxDistanceMeters)) +
        " " +
        getUnitsInMeterOrKm(mMaxDistanceMeters);
      dc.drawText(mWidth, 0, Graphics.FONT_XTINY, statsWptsTop, Graphics.TEXT_JUSTIFY_RIGHT);
    } else {
      dc.setColor(mFontColor, Graphics.COLOR_TRANSPARENT);
      dc.drawText(mWidth, 0, Graphics.FONT_XTINY, mPoiSet, Graphics.TEXT_JUSTIFY_RIGHT);
      var statsProxy = mCurrentLocation.infoLocation() + " " + mCurrentLocation.infoAccuracy();
      dc.drawText(0, 0, Graphics.FONT_XTINY, statsProxy, Graphics.TEXT_JUSTIFY_LEFT);

      statsWptsTop =
        "< " +
        getDistanceInMeterOrKm(mMinDistanceMeters).format(getFormatForMeterAndKm(mMinDistanceMeters)) +
        " " +
        getUnitsInMeterOrKm(mMinDistanceMeters) +
        " > " +
        getDistanceInMeterOrKm(mMaxDistanceMeters).format(getFormatForMeterAndKm(mMaxDistanceMeters)) +
        " " +
        getUnitsInMeterOrKm(mMaxDistanceMeters);
      var statsWptsTopWH = dc.getTextDimensions(statsWptsTop, Graphics.FONT_XTINY);
      dc.setColor(mFontStatsColor, Graphics.COLOR_TRANSPARENT);
      dc.drawText(0, statsWptsTopWH[1], Graphics.FONT_XTINY, statsWptsTop, Graphics.TEXT_JUSTIFY_LEFT);
    }
    
    var statsTravel = "";

    if ($.g_alert_closeRangeMeters > 0 && mCloseRangeList.size() > 0) {
      statsTravel = mCloseRangeList.size().format("%d");
    }
    if ($.g_alert_proximityMeters > 0 && mProximityList.size() > 0) {
      statsTravel = statsTravel + " / " + mProximityList.size().format("%d");
    }
    if (statsTravel.length() > 0) {
      statsTravel = statsTravel + " ";
      if (!mTinyField) {
        statsTravel = statsTravel + "range/hit";
      }
      var statsTravelWH = dc.getTextDimensions(statsTravel, Graphics.FONT_XTINY);
      dc.drawText(mWidth, statsTravelWH[1], Graphics.FONT_XTINY, statsTravel, Graphics.TEXT_JUSTIFY_RIGHT);
    }

    dc.setColor(mFontColor, Graphics.COLOR_TRANSPARENT);
    var x1 = mWidth / 2;
    var y1 = mHeight / 2;
    var lat = mCurWpt.lat;
    var lon = mCurWpt.lon;
    // Draw 'Center' a little to the bottom
    y1 = (y1 + y1 / 2).toNumber();

    var mapLonRight = lon - mZoomRange;
    var mapLonLeft = lon + mZoomRange;
    var mapLatBottom = lat;
    if ($.gDebug) {
      System.println(
        Lang.format("Stats #wpts[$1$] distance min[$2$] max[$2$] zoom range[$3$]", [
          mWptCount,
          mMinDistanceMeters,
          mMaxDistanceMeters,
          mZoomRange,
        ])
      );
    }

    var wptKm1 = getWayPointByDistanceAndHeading(lat, lon, 90d, 1d);
    var ptkm1 = convertGeoToPixel(wptKm1.lat, wptKm1.lon, mWidth, mHeight, mapLonRight, mapLonLeft, mapLatBottom);

    var radius_km1 = ptkm1.x - x1;
    if (radius_km1 < 0) {
      radius_km1 = radius_km1 * -1.0;
    }

    if ($.g_alert_closeRangeMeters > 0) {
      dc.setColor(Graphics.COLOR_ORANGE, Graphics.COLOR_TRANSPARENT);
      dc.drawCircle(x1, y1, radius_km1 * ($.g_alert_closeRangeMeters / 1000.0f));
    }
    if ($.g_alert_proximityMeters > 0) {
      dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
      dc.drawCircle(x1, y1, radius_km1 * ($.g_alert_proximityMeters / 1000.0f));
    }

    // draw 1 km circle, then per 1km and after 5km per 5km increase.
    dc.setColor(km1RangeColor, Graphics.COLOR_TRANSPARENT);
    dc.drawCircle(x1, y1, radius_km1);
    if (showCircleDistance) {
      dc.drawText(
        x1 + radius_km1 - 3,
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
          x1 + cradius - 3,
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

    // Draw longest distance first
    for (var i = mWptsSorted.size() - 1; i >= 0; i--) {
      var wpt = mWptsSorted[i];

      var distanceKm = wpt.distanceMeters / 1000.0f; //  $.getDistanceFromLatLonInKm(lat, lon, wpt.lat, wpt.lon);
      var bearing = wpt.bearing; // $.getRhumbLineBearing(lat, lon, wpt.lat, wpt.lon);

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

      // auto rotate point for display, actual bearing to the point stays the
      // same (ie ENE stays ENE from current point!) display is relative to top
      // of the edge device
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
      // var distanceMeters = distanceKm * 1000.0f;
      if (showDistance) {
        text =
          getDistanceInMeterOrKm(wpt.distanceMeters).format(getFormatForMeterAndKm(wpt.distanceMeters)) +
          " " +
          getUnitsInMeterOrKm(wpt.distanceMeters);
      }
      if (showDirection) {
        text = text + "(" + $.getCompassDirection(bearing) + ")";
      }

      var px = pt.x;
      var py = pt.y;
      var targetVisible = true;
      // points outside the screen -> draw only until the border
      if (px < 0 || px > mWidth || py < 0 || py > mHeight) {
        // https://en.wikipedia.org/wiki/Line%E2%80%93line_intersection#Given_two_points_on_each_line_segment
        // calc t and u for top border, right border, bottom border and left
        // border with wpt intersect with top border
        var pInter = intersect(0, 0, mWidth, 0, x1, y1, px, py);
        if (pInter == null) {
          // right
          pInter = intersect(mWidth, 0, mWidth, mHeight, x1, y1, px, py);
          if (pInter == null) {
            // bottom
            pInter = intersect(0, mHeight, mWidth, mHeight, x1, y1, px, py);
            if (pInter == null) {
              // left
              pInter = intersect(0, 0, 0, mHeight, x1, y1, px, py);
            }
          }
        }
        if (pInter != null) {
          px = pInter.x;
          py = pInter.y;
          targetVisible = false;
        }
      }

      if (targetVisible || wpt.distanceMeters <= mMinDistanceMeters) {
        dc.setColor(mLineColor, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        dc.drawLine(x1, y1, px, py);
        dc.setPenWidth(1);
        if (text.length() > 0) {
          dc.setColor(mFontColor, Graphics.COLOR_TRANSPARENT);
          if (px < mWidth / 2) {
            dc.drawText(
              px + mWptRadius + 2,
              py,
              mFontWptLabel,
              text,
              Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER
            );
          } else {
            dc.drawText(
              px - mWptRadius - 2,
              py,
              mFontWptLabel,
              text,
              Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER
            );
          }
        }

        dc.setColor(mTargetColor, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(px, py, mWptRadius);

        if (mFlashWaypoint && wpt.distanceMeters < $.g_alert_closeRangeMeters && !wpt.flashed) {
          dc.setColor(mTargetColor, Graphics.COLOR_TRANSPARENT);
          dc.drawCircle(px, py, mWptRadius + 2);
          dc.drawCircle(px, py, mWptRadius + 4);
          dc.drawCircle(px, py, mWptRadius + 6);
          wpt.flashed = true;
        }
      } else {
        if ($.gDistance_grayscale && $.gCreateColors) {
          var perc = percentageOf(wpt.distanceMeters, mMaxDistanceMeters); // mMinDistanceMeters
          var lineColor = percentageToColorAlt(perc, 255, $.PERC_COLORS_SCHEME_DIST, 0);
          dc.setColor(lineColor, Graphics.COLOR_TRANSPARENT);
        } else {
          dc.setColor(mLongLineColor, Graphics.COLOR_TRANSPARENT);
        }
        dc.drawLine(x1, y1, px, py);

        // @@ draw distance dots . per km @@ TODO how to visualize that one is
        // close by and other long distance grayscale colors? if < 10km draw
        // triangle black < 4km grey < 10km if (py >= mHeight) {
        //   // bottom
        //   var dotsCount = 1 + distanceKm % 10;
        //   for(var d=0)
        // }
      }
    }

    mFlashWaypoint = false;

    // Stats
    dc.setColor(mFontColor, Graphics.COLOR_TRANSPARENT);

    var statsWpts = "wpts #" + mWptCount.format("%d");
    var statsWptsWH = dc.getTextDimensions(statsWpts, Graphics.FONT_XTINY);
    dc.drawText(0, mHeight - statsWptsWH[1], Graphics.FONT_XTINY, statsWpts, Graphics.TEXT_JUSTIFY_LEFT);

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

    // Show track on top
    if (showTrack) {
      dc.setColor(trackColor, Graphics.COLOR_TRANSPARENT);
      dc.drawText(mWidth / 2, 0, Graphics.FONT_SMALL, $.getCompassDirection(track), Graphics.TEXT_JUSTIFY_CENTER);
      if (!mTinyField) {
        var trackH1 = dc.getFontHeight(Graphics.FONT_SMALL);
        dc.setColor(mFontColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(mWidth / 2, trackH1, Graphics.FONT_SYSTEM_TINY, track.format("%d"), Graphics.TEXT_JUSTIFY_CENTER);
      }
    }
    if (mWptCount == 0 && mBGServiceHandler.getRequestCounter() == 0) {
      var next = mBGServiceHandler.getWhenNextRequest("");
      var status = "";
      if (mBGServiceHandler.hasError()) {
        status = mBGServiceHandler.getError();
      } else {
        status = mBGServiceHandler.getStatus();
      }
      stats = mBGServiceHandler.getErrorMessage() + " " + status + "(" + next + ")";

      dc.setColor(mFontColor, Graphics.COLOR_TRANSPARENT);
      dc.drawText(
        mWidth / 2,
        mHeight / 2,
        Graphics.FONT_SYSTEM_SMALL,
        stats,
        Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
      );
    }
  }

  function calculatePoiStats(lat as Double, lon as Double) as Void {
    // Calc distance and bearing
    // Sort wpts from low to high

    var numberInCloseRange = 0;
    var numberProximity = 0;

    var wptsNeeded = $.g_sf_ZoomMinWayPoints;
    var zoomOnOneMeters = $.g_sf_zoomOneMeters;
    if (mLargeField) {
      wptsNeeded = $.g_lf_ZoomMinWayPoints;
      zoomOnOneMeters = $.g_lf_zoomOneMeters;
    } else if (mTinyField) {
      wptsNeeded = $.g_tf_ZoomMinWayPoints;
      zoomOnOneMeters = $.g_tf_zoomOneMeters;
    }

    mWptsSorted = [] as Array<WayPoint>;
    var min = 0.0f;
    var max = 0.0f;
    var count = mWpts.size();
    for (var i = 0; i < count; i++) {
      var wpt = mWpts[i];
      wpt.distanceMeters = $.getDistanceFromLatLonInKm(lat, lon, wpt.lat, wpt.lon) * 1000.0f;
      wpt.bearing = $.getRhumbLineBearing(lat, lon, wpt.lat, wpt.lon);
      // Check if was a hit after new payload
      wpt.hit = wpt.hit || wasInProximity(wpt);
      if (max == 0.0f || wpt.distanceMeters > max) {
        max = wpt.distanceMeters;
      }

      // Ignore this wpt if distance out of range after 'hit' (in proximity)
      var ignoreWptDistance = $.g_loosefocusafterhit && wpt.hit && wpt.distanceMeters > $.g_alert_closeRangeMeters;
      if ((min == 0.0f || wpt.distanceMeters < min) && !ignoreWptDistance) {
        min = wpt.distanceMeters;
      }

      // if (wptsNeeded > 1) {
      // Add sorted - small to long distance -> reverse is order to draw lines
      var ssize = mWptsSorted.size();
      if (ssize == 0) {
        mWptsSorted.add(wpt);
      } else if (ssize == 1) {
        mWptsSorted.add(wpt);
        if (wpt.distanceMeters < mWptsSorted[0].distanceMeters) {
          mWptsSorted = mWptsSorted.reverse();
        }
      } else {
        var idxA = 0;
        var idxB = idxA + 1;
        var insertIdx = -1; // insert before
        while (idxB < ssize && insertIdx < 0) {
          if (wpt.distanceMeters < mWptsSorted[idxA].distanceMeters) {
            insertIdx = idxA;
          } else if (
            mWptsSorted[idxA].distanceMeters <= wpt.distanceMeters &&
            wpt.distanceMeters <= mWptsSorted[idxB].distanceMeters
          ) {
            insertIdx = idxB;
          }

          idxA++;
          idxB = idxA + 1;
        }
        if (insertIdx < 0) {
          // longest distance
          mWptsSorted.add(wpt);
        } else {
          var _sorted = [] as Array<WayPoint>;
          _sorted = mWptsSorted.slice(0, insertIdx);
          _sorted.add(wpt);
          _sorted.addAll(mWptsSorted.slice(insertIdx, mWptsSorted.size()));
          mWptsSorted = _sorted as Array<WayPoint>;
        }
      }
      //}

      if ($.g_alert_closeRangeMeters > 0 && wpt.distanceMeters < $.g_alert_closeRangeMeters) {
        numberInCloseRange = numberInCloseRange + processCloseRange(wpt);
      }
      if ($.g_alert_proximityMeters > 0 && wpt.distanceMeters < $.g_alert_proximityMeters) {
        numberProximity = numberProximity + processProximity(wpt);
        wpt.hit = true;
      }
    }

    mWptCount = count;
    mMinDistanceMeters = min;
    if (min > zoomOnOneMeters && wptsNeeded > 1 && wptsNeeded < mWptsSorted.size()) {
      // Include the needed wpts by minimal distance
      mMinDistanceMeters = mWptsSorted[wptsNeeded].distanceMeters;
    }
    mMaxDistanceMeters = max;
    if ($.gDebug) {
      System.println(
        Lang.format("Poi Stats #wpts[$1$] distance min[$2$]meter max[$2$]meter newInCloseRange[$3$]", [
          mWptCount,
          mMinDistanceMeters,
          mMaxDistanceMeters,
          numberInCloseRange,
        ])
      );
    }

    if ($.g_alert_closeRange && numberInCloseRange > 0) {
      mFlashWaypoint = true;
      if (Attention has :ToneProfile) {
        var toneProfile =
          [
            new Attention.ToneProfile(1000, 40),
            new Attention.ToneProfile(1500, 150),
            new Attention.ToneProfile(3000, 0),
          ] as Lang.Array<Attention.ToneProfile>;
        Attention.playTone({ :toneProfile => toneProfile, :repeatCount => numberInCloseRange - 1 });
      }
    }

    if ($.g_alert_proximity && numberProximity > 0) {
      if (Attention has :ToneProfile) {
        var toneProfile =
          [
            new Attention.ToneProfile(1000, 30),
            new Attention.ToneProfile(1500, 50),
            new Attention.ToneProfile(3000, 0),
          ] as Lang.Array<Attention.ToneProfile>;
        Attention.playTone({ :toneProfile => toneProfile, :repeatCount => numberProximity - 1 });
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

  function wasInProximity(wpt as WayPoint) as Boolean {
    var key = Lang.format("$1$|$2$", [wpt.lon, wpt.lat]);
    return mProximityList.indexOf(key) > -1;
  }

  function processProximity(wpt as WayPoint) as Number {
    var key = Lang.format("$1$|$2$", [wpt.lon, wpt.lat]);
    var idx = mProximityList.indexOf(key);
    if (idx < 0) {
      mProximityList.add(key);
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
