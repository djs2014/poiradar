const gpxParse = require("gpx-parse");
const geomUtils = gpxParse.utils;
const osmUtils = require("./osmutil.js");

const metersInOneMile = 1609.34;

let waypoints = [];
let wptSets = [];

const { promises: { readFile } } = require("fs");
const path = require("path");

const wptFiles = [
    { "file": "../data/RIVM_20260704.json", "set": "20260704 drinkwaterkaart" },
    { "file": "../data/OSM_ALP_2026.geojson", "set": "Alps 2026 OSM" },
    { "file": "../data/OSM_PYR_2026.geojson", "set": "Pyrenees 2026 OSM" },
    { "file": "../data/OSM_NL_2026.geojson", "set": "NL 2026 OSM" },
];

// See app.js
// 0 = RIVM waterpoints (default)
// 1 = OSM set (overpass)
// 2 = OSM waterpoints
// 3 = OSM toilets
// 4 = File OSM ALP
// 5 = File OSM PYR
// 6 = File OSM NL
function getSetIdx(poiSet) {
    let idxSet = 0;
    
    if (poiSet === 4) {
        idxSet = 1; // alps
    } else if (poiSet === 5) {
        idxSet = 2; // pyrenees
    } else if (poiSet === 6) {
        idxSet = 3; // nl
    }
    return idxSet;
}

let isValidNumber = function (n) {
    return n != -1 && n != 0;
}
let getWptsInRange = async function (lat, lon, maxRangeMeters, maxWpts, poiSet) {
    if (waypoints.length == 0) {
        await loadWaypoints();
    }
    let idxSet = getSetIdx(poiSet);
    let wpts = waypoints[idxSet];

    let wptsInRange = [];
    wpts.forEach(wpt => {
        // skip lat, lon 0 or -1
        if (isValidNumber(wpt.lat) && isValidNumber(wpt.lon)) {
            let miles = geomUtils.calculateDistance(lat, lon, wpt.lat, wpt.lon);
            let meters = miles * metersInOneMile;
            if (meters <= maxRangeMeters) {
                let w = {};
                w.lat = wpt.lat,
                    w.lon = wpt.lon,
                    w.d = Math.round(meters),
                    w.code = wpt.code;
                w.isAvailable = wpt.isAvailable;
                wptsInRange.push(w);
            }
        }
    });
    // @@ filter duplicates

    // Sort on distance close to far away
    wptsInRange.sort((a, b) => {
        return a.d - b.d;
    });

    return {
        "lat": lat,
        "lon": lon,
        "set_id": poiSet,
        "set": wptSets[idxSet],
        "range": maxRangeMeters,
        "pts": compress(wptsInRange.slice(0, maxWpts))
    }
}

// [[lat,lon],[lat,lon], ..]
let compress = function (waypoints) {
    let wpts = [];
    waypoints.forEach(wpt => {
        wpts.push([wpt.lat, wpt.lon, wpt.code, wpt.isAvailable]);
    });

    return wpts;
}

let loadWaypoints = async function (idxSet) {
    console.log("Current directory:", __dirname);

    let wpts = [];
    let wptsstring = "";
    let wptFile = wptFiles[idxSet];
    await readFile(path.resolve(__dirname, wptFile.file)).then(fileBuffer => {
        // console.log(fileBuffer.toString());
        wptsstring = fileBuffer.toString();
    }).catch(error => {
        console.error(error.message);
    });

    // TODO file1/file2 as backup
    wptFile = wptFiles[idxSet];
    let ext = path.extname(wptFile.file).toLowerCase();
    if (ext == '.gpx') {

        await gpxParse.parseGpx(wptsstring, function (error, data) {
            //do stuff
            wpts = data.waypoints;
            // todo load in sqllite
        });
    } else if (ext == '.json') {
        wpts = extractJsonWaypoints(wptsstring);
    } else if (ext == '.geojson') {
        wpts = extractGeoJsonWaypoints(wptsstring);
    } else {
        console.log("Unknown file extension: " + ext);
    }

    waypoints[idxSet] = wpts;
    wptSets[idxSet] = wptFile.set;
}

let extractJsonWaypoints = function (json) {
    let wpts = []; // .lat .lon
    try {
        var data = JSON.parse(json);
        for (const element of data.features) {
            //console.log(element);

            wpts.push({
                "lat": element.properties.latitude,
                "lon": element.properties.longitude,
                "code": 0,
                "isAvailable": 1
            })
        }

    } catch (err) {
        console.log(err);
    }
    return wpts;
}

let extractGeoJsonWaypoints = function (json) {
    let wpts = []; // .lat .lon
    try {
        var data = JSON.parse(json);
        for (const element of data.features) {
            // In GeoJSON format, coordinates are stored as [Longitude, Latitude] (X, Y order),
            //  which is the reverse of how people usually speak ("latitude, longitude").
            wpts.push({
                "lat": element.geometry.coordinates[1],
                "lon": element.geometry.coordinates[0],
                "code": osmUtils.extractCode(element.properties),
                "isAvailable": osmUtils.isAvailable(element.properties)
            })
        }

    } catch (err) {
        console.log(err);
    }
    return wpts;
}
exports.initialize = async function () {
    for (let i = 0; i < wptFiles.length; i++) {
        await loadWaypoints(i);
        let wpts = waypoints[i];
        let setName = wptSets[i];
        console.log("Loaded: " + wpts.length + " waypoints for set: " + setName);
    }
}

exports.getInRange = async function (lat, lon, maxRangeMeters, maxWpts, poiSet) {
    return await getWptsInRange(lat, lon, maxRangeMeters, maxWpts, poiSet);
}