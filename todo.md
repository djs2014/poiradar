
# poi radar
hide track info field ENE and degrees
show outer search range


label distance circles 1 px left
??- direction to wpt same as heading +/- 2 --> extra zoom out to see the wpt . It is blocked by the compass values.
- calc bearing onlocationchanged
- on pause fonts black / white
setting alert -> use backlight j/n attention.backlight(1) .. after 5 sec ..0

- focus on ahead -> and when distance of found > 1km
  - ?? when hit / range? after x distance - ignore this wpt -> zoom 
  + start after x km / x min 50km
  + stop after x km / xmin 150km

- option CacheResult j/n

color range distance lt grey to black (far way - closeby) when target not visibile
  - proximity meters - 20m
  - proximity alert / beep
  - range alert / beep

- max values check for maxRange, maxResult 100km / 100


  - show large field
    - waypoint direction
    - waypoint distance
    - extra range meters
    - fixed range meters
    - autozoom min wpts
  - show small field
    - waypoint direction
    - waypoint distance
    - extra range meters
    - fixed range meters
    - autozoom min wpts

## settings
reset delay 
delay alerts for x minutes
  - countdown starts on activity active 
  - ex. first hour no alerst, found poi, delay alerts is now 0
  - reset will set it back to x minutes, countdown starts
interval min
max range meters
max number of results
zoom max view, 500m 1km 2km 10km etc.
close range meters (with zoom)
rotate with heading yes/no
alerts
- beep in range
- beep close range
alert / toast message ? (works when not displayed?)
debug
- display bearings per 45 degree on 1 km circle
- compass bar on top ||N||NNE || etc

display:
  - #poi
  - distance of closed (in heading range -x .. bearing .. +x)
  - 

## 
- background process
  - check what weather -> 
- display
- center is current lat lon
- calc x/y based on lat lon 
- circles range 500 m / .. 1 km .. 50 km ..

- test set 
  
# server
proxy
 - load gpx file
 - query
   - all loc within range of 50km
   - max results lat/lon

rename to poiradar
datafield
- radar screen with dots
- current heading is leading / on top
  - range +/-x grad 
- show distance km + heading
- center is bike - line to wpt. longer distance color is lighter gray
- beep when in range (config 1 km)
- beep beep when close (config 200m)


poi
- waterpunten official
- waterpunten garmin / display name
- kastelen





