import Toybox.System;
// import Toybox.Communications; Not possible in datafield
import Toybox.Lang;

// module CommunicationsHelpers {

(:background)
class CustomErrors {
  static const ERROR_BG_NONE as Number = 0;      
  static const ERROR_BG_NO_API_KEY as Number = -9000;
  static const ERROR_BG_NO_POSITION as Number = -9001;
  static const ERROR_BG_NO_PROXY as Number = -9002;
  static const ERROR_BG_EXCEPTION as Number = -9003;
  static const ERROR_BG_EXIT_DATA_SIZE_LIMIT as Number = -9004;
  static const ERROR_BG_INVALID_BACKGROUND_TIME as Number = -9005;  
  static const ERROR_BG_NOT_SUPPORTED as Number = -9006;
  static const ERROR_BG_HTTPSTATUS as Number = -9007;
  static const ERROR_BG_NO_PHONE as Number = -9008;
  static const ERROR_BG_GPS_LEVEL as Number = -9009;
}

    function getCommunicationError(errorNr as Lang.Number?, http as Lang.Number?) as String {
          if (errorNr == null) {return "";}
          var error = errorNr as Number;
          if (error == 0) {return "Unknown";} //Communications.UNKNOWN_ERROR
          if (error == -1) {return "BLE error";} //Communications.BLE_ERROR
          if (error == -2) {return "BLE host timeout";} // Communications.BLE_HOST_TIMEOUT
          if (error == -3) {return "BLE server timeout";} // Communications.BLE_SERVER_TIMEOUT
          if (error == -4) {return "BLE no data";} // Communications.BLE_NO_DATA
          if (error == -5) {return "BLE req canceled";} // Communications.BLE_REQUEST_CANCELLED
          if (error == -101) {return "BLE queue full";} // Communications.BLE_QUEUE_FULL
          if (error == -102) {return "BLE req too large";} // Communications.BLE_REQUEST_TOO_LARGE
          if (error == -103) {return "BLE unkown send err";} // Communications.BLE_UNKNOWN_SEND_ERROR
          if (error == -104) {return "BLE conn. unavailable";} // Communications.BLE_CONNECTION_UNAVAILABLE
          if (error == -200) {return "HPPT invalid req headers";} // Communications.INVALID_HTTP_HEADER_FIELDS_IN_REQUEST
          if (error == -201) {return "HTTP invalid req body";} // Communications.INVALID_HTTP_BODY_IN_REQUEST
          if (error == -202) {return "HTTP invalid req method";} // Communications.INVALID_HTTP_METHOD_IN_REQUEST
          if (error == -300) {return "Network req timeout";} // Communications.NETWORK_REQUEST_TIMED_OUT
          if (error == -400) { return "HTTP invalid resp body";} // Communications.INVALID_HTTP_BODY_IN_NETWORK_RESPONSE
          if (error == -401) {return "HTTP invalid resp headers";} // Communications.INVALID_HTTP_HEADER_FIELDS_IN_NETWORK_RESPONSE
          if (error == -402) {return "HTTP resp too large";} // Communications.NETWORK_RESPONSE_TOO_LARGE
          if (error == -403) {return "HTTP resp out of memory";} // Communications.NETWORK_RESPONSE_OUT_OF_MEMORY
          if (error == -1000) {return "Storage full";} // Communications.STORAGE_FULL
          if (error == -1001) {return "Secure connection required";} // Communications.SECURE_CONNECTION_REQUIRED
          if (error == -1002) {return "HTTP unsupported content-type";} // Communications.UNSUPPORTED_CONTENT_TYPE_IN_RESPONSE
          if (error == -1003) {return "HTTP req canceled";} // Communications.REQUEST_CANCELLED
          if (error == -1004) {return "HTTP conn dropped";} // Communications.REQUEST_CONNECTION_DROPPED
          if (error == -1005) {return "Unable to process media";} // Communications.UNABLE_TO_PROCESS_MEDIA
          if (error == -1006) {return "Unable to process image";} // Communications.UNABLE_TO_PROCESS_IMAGE
          if (error == -1007) {return "Unable to process HLS";} // Communications.UNABLE_TO_PROCESS_HLS

          if (error == CustomErrors.ERROR_BG_NO_API_KEY) {return "No API key";}
          if (error == CustomErrors.ERROR_BG_NO_POSITION) {return "No position";}
          if (error == CustomErrors.ERROR_BG_NO_PROXY) {return "No proxy";}
          if (error == CustomErrors.ERROR_BG_EXCEPTION) {return "Exception";}
          if (error == CustomErrors.ERROR_BG_EXIT_DATA_SIZE_LIMIT) {return "Response too large";}
          if (error == CustomErrors.ERROR_BG_INVALID_BACKGROUND_TIME) {return "Invalid bg time";}
          if (error == CustomErrors.ERROR_BG_NOT_SUPPORTED) {return "Bg not supported";}
          if (error == CustomErrors.ERROR_BG_NO_PHONE) {return "No phone";}
          if (error == CustomErrors.ERROR_BG_GPS_LEVEL) {return "Gps quality";}
          if (error == CustomErrors.ERROR_BG_HTTPSTATUS) {
            if (http != null) { return "Http [" + (http as Number).format("%0d") + "]"; }
            return "Http [???]";
          }            

        return error.format("%d");
      }
// }