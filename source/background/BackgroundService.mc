import Toybox.Application;
import Toybox.Lang;
import Toybox.Time;
import Toybox.System;
import Toybox.Background;
import Toybox.Sensor;
import Toybox.Application.Storage;
import Toybox.Communications;
// using CommunicationsHelpers as Helpers;

(:background)
class BackgroundServiceDelegate extends System.ServiceDelegate {
  function initialize() {
    System.println("BackgroundServiceDelegate initialize");
    ServiceDelegate.initialize();
  }

  public function onTemporalEvent() as Void {
    System.println("BackgroundServiceDelegate onTemporalEvent");

    var error = handlePOI();
    System.println("BackgroundServiceDelegate result handlePOI " + error);
    if (error != 0) {
      Background.exit(error);
    }
  }

  function handlePOI() as Number {
    try {
      System.println("BackgroundServiceDelegate handlePOI");
      // Get url
      // Get paramters: lat, lon, maxRange (meters), maxWpt (# results)
      // GET http://localhost:4000/poi?lat=52.15150518174673&lon=4.774347540760808;6
      //    &poi=waterpunt&maxWpts=100&maxRange=30000
      //Authorization: 0548b3c7-61bc-4afc-b6e5-616f19d3cf23

      var location = Storage.getValue("latest_latlng");
      var poiUrl = Storage.getValue("poiUrl");
      var poiAPIKey = Storage.getValue("poiAPIKey");
      var apiVersion = "1.0";
      var maxRange = Storage.getValue("maxRangeMeters");
      var maxWpts = Storage.getValue("maxWaypoints");
      var poiSet = Storage.getValue("poiSet");

      System.println(
        Lang.format("Url[$1$] location [$2$] apiKey[$3$] apiVersion[$4$] maxRange[$5$] maxWpts[$6$] poiSet[$7$]", [
          poiUrl,
          location,
          poiAPIKey,
          apiVersion,
          maxRange,
          maxWpts,
          poiSet,
        ])
      );

      if (poiUrl == null) {
        poiUrl = "";
      }
      if (poiAPIKey == null) {
        poiAPIKey = "";
      }

      if (location == null) {
        return CustomErrors.ERROR_BG_NO_POSITION;
      }
      if ((poiAPIKey as String).length() == 0) {
        return CustomErrors.ERROR_BG_NO_API_KEY;
      }
      if ((poiUrl as String).length() == 0) {
        return CustomErrors.ERROR_BG_NO_PROXY;
      }
      if (maxRange == null) {
        maxRange = 30000;
      }
      if (maxWpts == null) {
        maxWpts = 50;
      }
      if (poiSet == null) {
        poiSet = "";
      }
      var lat = (location as Array)[0] as Double;
      var lon = (location as Array)[1] as Double;
      if ((lat >= 179.99 || lat <= -179.99) && (lon >= 179.99 || lon <= -179.99)) {
        System.println("1 Invalid location lat[" + lat + "] lon[" + lon + "] exit background service");
        return CustomErrors.ERROR_BG_NO_POSITION;
      }

      var params = {
        "version" => apiVersion as String,
        "lat" => lat,
        "lon" => lon,
        "maxRange" => maxRange as Number,
        "maxWpts" => maxWpts as Boolean,
        "poiSet" => poiSet as String,
      };
      requestData(poiUrl as String, poiAPIKey as String, params);
      return 0;
    } catch (ex) {
      System.println("1");
      System.println(ex.getErrorMessage());
      ex.printStackTrace();
      return CustomErrors.ERROR_BG_EXCEPTION;
    }
  }

  function requestData(poiUrl as String, poiAPIKey as String, params as Lang.Dictionary) as Void {
    var options = {
      :method => Communications.HTTP_REQUEST_METHOD_GET,
      :headers => {
        "Content-Type" => Communications.REQUEST_CONTENT_TYPE_JSON,
        "Accept" => "application/json",
        "Authorization" => poiAPIKey,
      },
      :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON,
    };
    var responseCallBack = method(:onReceiveResponse);

    Communications.makeWebRequest(poiUrl, params, options, responseCallBack);
  }

  function onReceiveResponse(
    responseCode as Lang.Number,
    responseData as Lang.Dictionary or Null or Lang.String
  ) as Void {
    try {
      var curTime = System.getClockTime();
      System.println(
        "onReceiveResponse time " +
          curTime.hour.format("%02d") +
          ":" +
          curTime.min.format("%02d") +
          ":" +
          curTime.sec.format("%02d")
      );
      System.println("onReceiveResponse responseCode " + responseCode);
      if (responseCode == 200 && responseData != null) {
        System.println("onReceiveResponse responseData not null");
        // !! Do not convert responseData to string (println etc..) --> gives out of memory
        //System.println(responseData);   --> gives out of memory
        // var data = responseData as String;  --> gives out of memory
        Background.exit(responseData as PropertyValueType);
      } else {
        System.println("Not 200");
        System.println(responseData);
        Background.exit(responseCode);
      }
    } catch (ex instanceof Background.ExitDataSizeLimitException) {
      System.println(ex.getErrorMessage());
      ex.printStackTrace();
      Background.exit(CustomErrors.ERROR_BG_EXIT_DATA_SIZE_LIMIT);
    } catch (ex) {
      System.println(ex.getErrorMessage());
      ex.printStackTrace();
      //System.println(responseData);
      Background.exit(CustomErrors.ERROR_BG_EXCEPTION);
    }
  }
}
