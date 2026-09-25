https://overpass-turbo.eu

- define map
- run query
- export GeoJSON
- copy raw query

# Custom local sets

## drinking_water + toilets + properties
/*
OSM_PYR_2026
Region Pyreneeen / Girona
*/
[out:json][timeout:60];nwr["amenity"~"^(toilets|drinking_water)$"](41.157802,-1.712877,44.684111,4.950330);out tags center;

/*
OSM_ALP_2026
Region Alps
*/
[out:json][timeout:60];nwr["amenity"~"^(toilets|drinking_water)$"](45.112135,5.954345,48.410817,12.617553);out tags center;

/*
OSM_NL_2026
Netherlands
*/
[out:json][timeout:60];nwr["amenity"~"^(toilets|drinking_water)$"](50.049592,3.025890,53.971792,7.552257);out tags center;

-------------

// Simple
[out:json][timeout:60];
node
  [amenity=drinking_water]
  (45.11213527276001,5.954345903493047,48.41081744458227,12.617553911305547);
out skel center;


To keep the response payload extremely small and fast, use out skel; (or out ids center;) instead of standard out body;. This tells Overpass to strip all tag metadata and return only IDs and coordinates (lat, lon).
Here is the query using a 2 km search radius (around:2000) around target coordinates (e.g., 52.1, 4.5):;

node & way: Queries both point features (nodes) and mapped areas like water fountains in parks (ways).
[out:json]: Returns clean JSON instead of XML.
around:2000, lat, lon: Sets the search radius in meters around your coordinates.
out skel center;:
skel (skeleton) drops all metadata, tags, and timestamps, returning only coordinates.
center forces way elements to output a single calculated center point (lat/lon).

[out:json][timeout:10];
(
  node["amenity"="drinking_water"](around:2000, 52.1, 4.5);
  way["amenity"="drinking_water"](around:2000, 52.1, 4.5);
);
out skel center;


https://wiki.openstreetmap.org/wiki/Overpass_API

Executing via Node.js / HTTP POST
You can send this query directly to the Overpass API endpoint ([https://overpass-api.de/api/interpreter](https://overpass-api.de/api/interpreter)):



```
const axios = require('axios');

async function getNearbyWater(lat, lon, radiusMeters = 2000) {
  const query = `
    [out:json][timeout:10];
    (
      node["amenity"="drinking_water"](around:${radiusMeters},${lat},${lon});
      way["amenity"="drinking_water"](around:${radiusMeters},${lat},${lon});
    );
    out skel center;
  `;

  try {
    const response = await axios.post(
      'https://overpass-api.de/api/interpreter',
      `data=${encodeURIComponent(query)}`,
      { headers: { 'Content-Type': 'application/x-www-form-urlencoded' } }
    );

    // Extract minimal lat/lon array
    const locations = response.data.elements.map(el => ({
      lat: el.lat || (el.center ? el.center.lat : null),
      lon: el.lon || (el.center ? el.center.lon : null)
    })).filter(loc => loc.lat && loc.lon);

    return locations;
  } catch (error) {
    console.error('Overpass API error:', error.message);
    return [];
  }
}

// Example usage
getNearbyWater(52.1, 4.5, 2000).then(console.log);
```

response
```
[
  { "lat": 52.102341, "lon": 4.501231 },
  { "lat": 52.098812, "lon": 4.495110 }
]
```

{
  "type": "node",
  "id": 278208675,
  "lat": 52.1626949,
  "lon": 4.3487449
},



```
/**
 * Calculates straight-line distance in meters between two lat/lon points.
 */
function getDistanceMeters(lat1, lon1, lat2, lon2) {
  const R = 6371000; // Earth's radius in meters
  const dLat = (lat2 - lat1) * (Math.PI / 180);
  const dLon = (lon2 - lon1) * (Math.PI / 180);
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(lat1 * (Math.PI / 180)) *
      Math.cos(lat2 * (Math.PI / 180)) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);

  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

/**
 * Sorts locations by proximity and returns top N closest.
 */
function getClosestLocations(currentLat, currentLon, locations, limit = 5) {
  return locations
    .map(loc => ({
      ...loc,
      dist: Math.round(getDistanceMeters(currentLat, currentLon, loc.lat, loc.lon))
    }))
    .sort((a, b) => a.dist - b.dist)
    .slice(0, limit);
}

// Example usage:
const origin = { lat: 52.1000, lon: 4.5000 };
const rawWaterNodes = [
  { lat: 52.1200, lon: 4.5100 },
  { lat: 52.1010, lon: 4.5020 },
  { lat: 52.1080, lon: 4.4900 }
];

const closest3 = getClosestLocations(origin.lat, origin.lon, rawWaterNodes, 3);
console.log(closest3);
```

Optimization Tip for Micro-Distances: Over short distances (e.g., within 2–5 km), calculating expensive trigonometric functions like sin/atan2 is unnecessary. You can approximate distance using the equirectangular projection, which is ~10x faster:

```
function getFastDistanceApprox(lat1, lon1, lat2, lon2) {
  const x = (lon2 - lon1) * Math.cos((lat1 + lat2) * 0.00872664625); // Math.PI / 360
  const y = lat2 - lat1;
  return Math.sqrt(x * x + y * y) * 111000; // Approx meters
}
```
