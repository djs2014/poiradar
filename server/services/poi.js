const gpxParse = require("gpx-parse");
const geomUtils = gpxParse.utils;

const metersInOneMile = 1609.34;

let waypoints = [];

const { promises: { readFile } } = require("fs");
const path = require("path");
// const gpxFile = '../data/202309Drinkwaterkaart.gpx';
// const gpxSet = '202309Drinkwaterkaart';
const gpxFile = '../data/rivm_20240502_drinkwaterkranen.gpx';
const gpxSet = '20240502Drinkwaterkaart';

let isValidNumber = function (n) {
    return n != -1 && n != 0;
}
let getWptsInRange = async function (lat, lon, maxRangeMeters, maxWpts) {
    if (waypoints.length == 0) {
        console.log("Current directory:", __dirname);

        let wptsstring = "";
        await readFile(path.resolve(__dirname, gpxFile)).then(fileBuffer => {
            // console.log(fileBuffer.toString());
            wptsstring = fileBuffer.toString();
        }).catch(error => {
            console.error(error.message);
        });

        gpxParse.parseGpx(wptsstring, function (error, data) {
            //do stuff
            waypoints = data.waypoints;
            // todo load in sqllite
        });
    }

    // TODO sorted list on distance
    // TODO load both/all gpx files
    let wptsInRange = [];
    waypoints.forEach(wpt => {
        // skip lat, lon 0 or -1
        if (isValidNumber(wpt.lat) && isValidNumber(lon)) {
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
        "set": gpxSet,
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



exports.getInRange = async function (lat, lon, maxRangeMeters, maxWpts) {

    return await getWptsInRange(lat, lon, maxRangeMeters, maxWpts);
}