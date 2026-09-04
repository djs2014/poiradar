const http = require("https");
const NodeCache = require('node-cache');
const osmUtils = require("./osmutil.js");

/*
Check status current ip: (rate limit 2 per minute)
https://overpass-api.de/api/status
*/

// 7 days in seconds
const SEVEN_DAYS = 7 * 24 * 60 * 60; // 604,800
const TWELVE_HOURS = 12 * 60 * 60;   // 43,200 seconds (for empty results)

// Initialize cache
const waterCache = new NodeCache({
    stdTTL: SEVEN_DAYS, // Default TTL for all new keys
    checkperiod: 3600              // Check and delete expired keys every 1 hour (3600s)
});

const getCacheKey = (lat, lon, radius, aminity) => {
    const gridLat = (Math.round(lat * 100) / 100).toFixed(2);
    const gridLon = (Math.round(lon * 100) / 100).toFixed(2);
    return `${aminity}:${gridLat}:${gridLon}:${radius}`;
}


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

function getFastDistanceApprox(lat1, lon1, lat2, lon2) {
    const x = (lon2 - lon1) * Math.cos((lat1 + lat2) * 0.00872664625); // Math.PI / 360
    const y = lat2 - lat1;
    return Math.sqrt(x * x + y * y) * 111000; // Approx meters
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

let compress = function (waypoints) {
    let wpts = [];
    waypoints.forEach(wpt => {
        wpts.push([wpt.lat, wpt.lon]);
    });

    return wpts;
}

const OVERPASS_ENDPOINTS = [
    'https://overpass-api.de/api/interpreter',         // Main server (Germany)
    'https://overpass.private.coffee/api/interpreter',  // Community mirror
    'https://maps.mail.ru/osm/tools/overpass/api/interpreter' // Alternative mirror
];

let endpointIndex = 0;

function getNextEndpoint() {
    const url = OVERPASS_ENDPOINTS[endpointIndex];
    endpointIndex = (endpointIndex + 1) % OVERPASS_ENDPOINTS.length;
    return url;
}

const { default: PQueue } = require('p-queue');

// Limit to 1 request at a time, with a minimum 2-second delay between requests
const overpassQueue = new PQueue({
    concurrency: 1,
    intervalCap: 1,
    interval: 2000
});


function normalizeRadius(meters) {
    if (meters <= 2000) return 2000;
    if (meters <= 5000) return 5000;
    if (meters <= 10000) return 10000;
    if (meters <= 15000) return 15000;
    if (meters <= 20000) return 20000;
    return 20000;
}

async function fetchOverpassWithFallback(query) {
    // Encode the body using URLSearchParams
    const body = new URLSearchParams();
    body.append('data', query);

    for (const endpoint of OVERPASS_ENDPOINTS) {
        try {
            console.log(`Trying endpoint: ${endpoint}`);
            const response = await fetch(endpoint, {
                method: 'POST',
                headers: {
                    // Overpass requires a unique User-Agent to prevent anonymous scraping blocks
                    'User-Agent': 'GarminConnectIQ_POIradar/2.0 (dirk.speelman@gmail.com)',
                    'Accept': 'application/json',
                    'Accept-Encoding': 'gzip, deflate'
                },
                body: body,
                signal: AbortSignal.timeout(15000) // 15-second request timeout
            });

            // If server returns 500/502/504, skip to the next mirror
            if (!response.ok) {
                console.warn(`Endpoint ${endpoint} failed with HTTP ${response.status}. Trying next...`);
                continue;
            }

            const data = await response.json();
            return data; // Return successfully on first good response

        } catch (err) {
            console.warn(`Endpoint ${endpoint} request failed: ${err.message}. Trying next...`);
        }
    }

    throw new Error('All Overpass API mirrors failed to respond.');
}

async function getNearbyAmenity(lat, lon, radiusMeters = 5000, aminity = 'drinking_water') {
    radiusMeters = normalizeRadius(radiusMeters);

    // Check cache first
    const cacheKey = getCacheKey(lat, lon, radiusMeters, aminity);
    const cachedData = waterCache.get(cacheKey);
    if (cachedData !== undefined) {
        console.log(`Cache HIT for key: ${cacheKey}`);
        return cachedData;
    }

    var timeout = 10; // 10 seconds
    if (radiusMeters >= 10000) {
        timeout = 25; // 30 seconds for larger queries
    }
    if (radiusMeters > 25000) {
        radiusMeters = 25000; // Limit to 25km radius
        timeout = 40;
    }
    const query = `
    [out:json][timeout:${timeout}];
    (
      node["amenity"="${aminity}"](around:${radiusMeters},${lat},${lon});
      way["amenity"="${aminity}"](around:${radiusMeters},${lat},${lon});
    );
    out skel center;
  `;


    try {
        // Use the queue to ensure we respect Overpass API rate limits
        return overpassQueue.add(async () => {
            const data = await fetchOverpassWithFallback(query);

            // Map to clean lat/lon coordinates
            const cleanData = data.elements
                .map(el => ({
                    lat: el.lat || (el.center ? el.center.lat : null),
                    lon: el.lon || (el.center ? el.center.lon : null)
                }))
                .filter(loc => loc.lat !== null && loc.lon !== null);

            // Apply Two-Tier Caching
            if (Array.isArray(cleanData) && cleanData.length > 0) {
                // Cache valid data for 7 days
                waterCache.set(cacheKey, cleanData, SEVEN_DAYS);
            } else if (Array.isArray(cleanData) && cleanData.length === 0) {
                console.log(`No waypoints found for key: ${cacheKey}. Caching empty result for 12 hours.`);
                // Negative cache: Cache empty array for 12 hours
                waterCache.set(cacheKey, [], TWELVE_HOURS);
            }

            return cleanData;
        });

    } catch (error) {
        console.error('Fetch error:', error.message);
        return [];
    }
}

let getWptsInRange = async function (lat, lon, maxRangeMeters, maxWpts, poiSet, aminity) {
    const nearbyWater = await getNearbyAmenity(lat, lon, maxRangeMeters, aminity);

    const closest = getClosestLocations(lat, lon, nearbyWater, maxWpts);

    // Filter down to user's actual requested distance
    const userClosest = closest.filter(node => node.dist <= maxRangeMeters);
    // Extract code and availability for each node
    userClosest.forEach(node => {
        node.code = osmUtils.extractCode(node.properties);
        node.isAvailable = osmUtils.isAvailable(node.properties);
    });

    return {
        "lat": lat,
        "lon": lon,
        "set_id": poiSet,
        "set": `OSM ${aminity}`,
        "range": maxRangeMeters,
        "pts": compress(userClosest.slice(0, maxWpts))
    }
};

function getAmenityForPoiSet(poiSet) {
    switch (poiSet) {
        case 1: // overpass waterpoints
            return "drinking_water";
        case 5: // toilets overpass
            return "toilets";
        default:
            console.warn(`Unknown poiSet: ${poiSet}. Defaulting to drinking_water.`);
            return "drinking_water";
    }
}

exports.getInRange = async function (lat, lon, maxRangeMeters, maxWpts, poiSet) {

    let aminity = getAmenityForPoiSet(poiSet);

    return await getWptsInRange(lat, lon, maxRangeMeters, maxWpts, poiSet, aminity);
}


// TODO: add caching of results to avoid repeated queries for same area
// @@ maxRangeMeters should be limited to avoid huge queries
/*
// Spatial Cache Key
const gridLat = (Math.round(lat * 100) / 100).toFixed(2);
const gridLon = (Math.round(lon * 100) / 100).toFixed(2);
const cacheKey = `water:${gridLat}:${gridLon}`;

// Read from Redis / Memory first
let waterNodes = await cache.get(cacheKey);
if (!waterNodes) {
  waterNodes = await fetchFromOverpass(gridLat, gridLon);
  await cache.set(cacheKey, waterNodes, 86400 * 7); // 7 days TTL
}


// Some fallback sets 
- nl
- pyr
- alp
  */