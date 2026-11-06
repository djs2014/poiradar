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
    try {
      System.println("BackgroundServiceDelegate onTemporalEvent");

      var error = handlePOI();
      System.println("BackgroundServiceDelegate result handlePOI " + error);
      if (error != 0) {
        Background.exit(error);
      }
    } catch (ex) {
      System.println("1");
      System.println(ex.getErrorMessage());
      ex.printStackTrace();
      Background.exit(CustomErrors.ERROR_BG_EXCEPTION);
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

      if (poiUrl == null) {
        poiUrl = "";
      }
      if (poiAPIKey == null) {
        poiAPIKey = "";
      }

      if (location == null) {
        return CustomErrors.ERROR_BG_NO_POSITION;
      }
      if (poiSet == null) {
        poiSet = 0; // Default to waterpunt
      }
      if (maxRange == null || (maxRange as Number) > 100000) {
        maxRange = 30000;
        Storage.setValue("maxRangeMeters", maxRange);
      }
      if (maxWpts == null || (maxWpts as Number) > 100) {
        maxWpts = 50;
        Storage.setValue("maxWaypoints", maxWpts);
      }

      var lat = (location as Array)[0] as Double;
      var lon = (location as Array)[1] as Double;
      if (
        (lat >= 179.99 || lat <= -179.99) &&
        (lon >= 179.99 || lon <= -179.99)
      ) {
        System.println(
          "Invalid location lat[" +
            lat +
            "] lon[" +
            lon +
            "] exit background service"
        );
        return CustomErrors.ERROR_BG_NO_POSITION;
      }
      var params =
        ({
          "version" => apiVersion as String,
          "lat" => lat,
          "lon" => lon,
          "maxRange" => maxRange as Number,
          "maxWpts" => maxWpts as Number,
          "poiSet" => poiSet as Number,
        }) as Lang.Dictionary<Lang.Object, Lang.Object>;

      // Direct Overpass query needs no proxy url/api key, literal 7 keeps
      // this background-safe (POISET_OVERPASS_WATER enum is not (:background)).
      if ((poiSet as Number) == 7) {
        return requestOverpassData(params);
      }

      System.println(
        Lang.format(
          "Url[$1$] location [$2$] apiKey[$3$] apiVersion[$4$] maxRange[$5$] maxWpts[$6$] poiSet[$7$]",
          [poiUrl, location, poiAPIKey, apiVersion, maxRange, maxWpts, poiSet]
        )
      );

      if ((poiAPIKey as String).length() == 0) {
        return CustomErrors.ERROR_BG_NO_API_KEY;
      }
      if ((poiUrl as String).length() == 0) {
        return CustomErrors.ERROR_BG_NO_PROXY;
      }

      requestData(poiUrl as String, poiAPIKey as String, params);
      return 0;
    } catch (ex) {
      System.println(ex.getErrorMessage());
      ex.printStackTrace();
      return CustomErrors.ERROR_BG_EXCEPTION;
    }
  }

  function requestOverpassData(
    params as Lang.Dictionary<Lang.Object, Lang.Object>
  ) as Number {
    try {
      var lat = params["lat"] as Lang.Double?;
      var lon = params["lon"] as Lang.Double?;
      var maxRange = params["maxRange"] as Lang.Number?;

      if (lat == null || lon == null) {
        return CustomErrors.ERROR_BG_NO_POSITION;
      }
      if (maxRange == null) {
        maxRange = 10000;
      }

      // Fixed, because result not order in closest by distance and to prevent out of memory
      maxRange = 5000; // TEST
      var maxWpts = 20;
      // Double.format("%.7f") uses C printf-style formatting, which is
      // locale-independent and always emits "." as decimal separator,
      // so no comma-to-dot replacement is needed.
      var latStr = (lat as Lang.Double).format("%.7f");
      var lonStr = (lon as Lang.Double).format("%.7f");
      var rangeStr = (maxRange as Lang.Number).format("%d");
      var amenity = "drinking_water"; //|toilets
      // POST https://overpass-api.de/api/interpreter
      // Content-Type: application/x-www-form-urlencoded
      // data=[out:json][timeout:10];(nwr["amenity"~"^(toilets|drinking_water)"](around:10000,50.0577228,4.5327728););out tags center;
      // out skel = minimal as possible, or out of memory
      var query = Lang.format(
        "[out:json][timeout:20];(nwr['amenity'='$1$'](around:$2$,$3$,$4$););out skel $5$;",
        [amenity, rangeStr, latStr, lonStr, maxWpts]
      );
      System.println(
        "Requesting Overpass data query[" +
          query +
          "]"
      );

      var url = "https://overpass-api.de/api/interpreter";
      var requestParams =
        ({
          "data" => query,
        }) as Lang.Dictionary<Lang.Object, Lang.Object>;
      var options = {
        :method => Communications.HTTP_REQUEST_METHOD_POST,
        :headers => {
          "Content-Type" => Communications.REQUEST_CONTENT_TYPE_URL_ENCODED,
        },
        :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON,
      };
      var responseCallBack = method(:onReceiveResponseOverpass);
      System.println(
        "Making Overpass web request with url[" + url + "] query[" + query + "]"
      );

      Communications.makeWebRequest(
        url,
        requestParams,
        options,
        responseCallBack
      );
      return 0;
    } catch (ex) {
      System.println(ex.getErrorMessage());
      ex.printStackTrace();
      return CustomErrors.ERROR_BG_EXCEPTION;
    }
  }
  function requestData(
    poiUrl as String,
    poiAPIKey as String,
    params as Lang.Dictionary<Lang.Object, Lang.Object>
  ) as Void {
    try {
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
    } catch (ex) {
      System.println(ex.getErrorMessage());
      ex.printStackTrace();
    }
  }

  function onReceiveResponseOverpass(
    responseCode as Lang.Number,
    responseData as Lang.Dictionary or Null or Lang.String
  ) as Void {
    try {
      var curTime = System.getClockTime();
      System.println(
        "onReceiveResponseOverpass time " +
          curTime.hour.format("%02d") +
          ":" +
          curTime.min.format("%02d") +
          ":" +
          curTime.sec.format("%02d")
      );
      System.println("onReceiveResponseOverpass responseCode " + responseCode);
      if (responseCode == 200 && responseData != null) {
        System.println("onReceiveResponseOverpass responseData not null");
        // !! Do not convert responseData to string (println etc..) --> gives out of memory
        Background.exit(responseData as PropertyValueType);
      } else if (responseCode == 504) {
        // Overpass gateway timeout (query too heavy): transient, foreground
        // treats it as non-fatal and retries on the next temporal event.
        System.println("Overpass gateway timeout");
        Background.exit(CustomErrors.ERROR_BG_GATEWAY_TIMEOUT);
      } else {
        System.println("Response data:");
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
      Background.exit(CustomErrors.ERROR_BG_EXCEPTION);
    }
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
      } else if (responseCode == 504) {
        // Gateway timeout: transient, foreground treats it as non-fatal.
        System.println("Gateway timeout");
        Background.exit(CustomErrors.ERROR_BG_GATEWAY_TIMEOUT);
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
