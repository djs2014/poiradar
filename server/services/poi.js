const gpxParse = require("gpx-parse");
const geomUtils = gpxParse.utils;

const metersInOneMile = 1609.34;

let waypoints = [];

const { promises: { readFile } } = require("fs");
const path = require("path");

const wptFiles = [
    '../data/rivm_drinkwaterkranen_actueel_20260704.json',
    '../data/overpass-alp-waterpoints-2026.geojson',
    '../data/overpass-pyr-waterpoints-2026.geojson',
    '../data/overpass-nl-toilets-2026.geojson'
];
const wptSets = [
    '20260704Drinkwaterkaart',
    '2026Alps',
    '2026Pyrenees',
    '2026NLToilets'
];

function getSetIdx(poiSet) {
    let idxSet = 0;
    if (poiSet === 1) {
        idxSet = 0; // overpass is handled separately
    } else if (poiSet === 2) {
        idxSet = 1; // alps
    } else if (poiSet === 3) {
        idxSet = 2; // pyrenees
    } else if (poiSet === 4) {
        idxSet = 3; // nl toilets
    }
    return idxSet;
}

// const gpxFile = '../data/rivm_drinkwaterkranen_actueel_20260704.json';
// const gpxSet = '20260704Drinkwaterkaart';

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
                    // w.name = wpt.name
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
        "set": wptSets[idxSet],
        "range": maxRangeMeters,
        "pts": compress(wptsInRange.slice(0, maxWpts))
    }
}

// [[lat,lon],[lat,lon], ..]
let compress = function (waypoints) {
    let wpts = [];
    waypoints.forEach(wpt => {
        wpts.push([wpt.lat, wpt.lon]);
    });

    return wpts;
}

let loadWaypoints = async function (idxSet) {
    console.log("Current directory:", __dirname);

    let wpts = [];
    let wptsstring = "";
    let wptFile = wptFiles[idxSet];
    await readFile(path.resolve(__dirname, wptFile)).then(fileBuffer => {
        // console.log(fileBuffer.toString());
        wptsstring = fileBuffer.toString();
    }).catch(error => {
        console.error(error.message);
    });

    // TODO file1/file2 as backup
    wptFile = wptFiles[idxSet];
    let ext = path.extname(wptFile);
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
            //console.log(element);

            // In GeoJSON format, coordinates are stored as [Longitude, Latitude] (X, Y order), which is the reverse of how people usually speak ("latitude, longitude").

            wpts.push({
                "lat": element.geometry.coordinates[1],
                "lon": element.geometry.coordinates[0],
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