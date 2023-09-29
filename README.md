# Poi radar
Garmin ConnectIQ POI radar - drinkwaterkaart gpx

Currently only watertappoints from https://drinkwaterkaart.nl

Datafield displaying all watertappunten in your current location.
Currently only data from the Netherlands ([drinkwaterkaart.nl](https://drinkwaterkaart.nl))


# Settings

- Proxy
  - Set minimal needed gps quality
  - Interval check poi data (background) in minutes
  - Maximum search range for poi data
  - Maximum number of poi

- Large field: screen with 1 field
  - Show waypoint direction (Ex: NE)
  - Show waypoint distance in km or meters
  - Show ranges per km for the circles
  - Include Extra meters in display range (autozoom)
  - Set a fixed range in meters (no autozoom)
  - Zoom will include this amount of waypoints

- Small field: the large screen (ex in 5B)
  - See Large field
- Tiny field: the smallest field
  - See Large field

- Alerts
  - Set the close by range in meters
  - Beep on close by
  - Set the proximity in meters (should be less than close by)
  - Boop on proximity (hit)
  - Loose focus after hit
    - Will zoom out ignore the poi after hit and distance greater than close by range. Effect: you will see sooner the other poi.

- Grayscale distance
  - Black: close by
  - Light gray: far away


- Debug
  - Draw something extra.
  - Will print


- Reset to defaults
  - Set default values