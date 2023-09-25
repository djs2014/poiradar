
# poi radar
-##/## inrange/hit ipv found
  + start after x km / x min 50km
  + stop after x km / xmin 150km
  - proximity meters - 20m
  - proximity alert / beep
  - range alert / beep

- when close by -> label with distance 
- focus on ahead -> and when distance of found > 1km
- max values check for maxRange, maxResult 100km / 100
- option CacheResult j/n
- cache json result after request -> string
- when start app -> use this data first

-store stats of encounterd poi elapseddistance at time
start after
show wpts visible on top -> draw as last
create test mode -
  - test set 
  - 
alert
  key is lat,lon
  + count # close by < 500m
  + beep / beep beep
  + toast message?
  - reset start -> refilled bottle 

min -> black color
settings:
  - debug
  - proxy
    - minimal gps quality
    - url
    - apikey
    - check interval minutes
    - max range meters
    - max waypoints
    - set : watertappunt
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

  -alerts
    // @@

display:
  lat/lon 
  poi stats
on big field bearing + km
on small only km

onCompute
 - when lat/lon changes
   - calc min/max distance and zoom and etc.
   - process alerts

onUpdate
  - draw thingies using zoom

background
  - get new wpts

- Show current heading ()
-  -- test
- Settings menu
  - Debug
  - rotate with heading yes/no
  - show bearing [SE]
- Background service 

- auto zoom:
    - check with field witdh / height
    - minimal 1 dot in screen  

- 500m circle is green
- 
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





