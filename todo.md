
TEST
-> call overpass api in Garmin
-> only returning lat,lon
-> only waterpoints or toilets

node app to create ALP/NL/PYR sets
node server/tools/createlocalsets.js -> timeouts

----------------
sync bg services to other apps

https://dataplatform.nl/#/home


# Download latest using JSON


poiset
- alps
- pyrenees

- overpass toilets -> color yellow
- combi possible?


- silent for x minutes / km
  use activity startLocation 

- weak references --> circular refs stuffs
- 
# poi radar
show outer search range
enable home beaken
  - save start lat,lon -> highlight when going back / roundtrip

? setting alert -> use backlight j/n attention.backlight(1) .. after 5 sec ..0

alerts
  + start after x km / x min 50km
  + stop after x km / xmin 150km
  reset delay 

- option CacheResult j/n

color range distance lt grey to black (far way - closeby) when target not visibile

- max values check for maxRange, maxResult 100km / 100

- test set 


## settings
delay alerts for x minutes
  - countdown starts on activity active 
  - ex. first hour no alerst, found poi, delay alerts is now 0
  - reset will set it back to x minutes, countdown starts

  - 


  
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






--------------
node  app.js
with debug
node --inspect app.js

VS Code: Open the command palette (Ctrl+Shift+P / Cmd+Shift+P), choose Debug: Attach to Node Process, and select your running app.js process.

npm install p-queue