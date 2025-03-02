const gpxParse = require("gpx-parse");
const geomUtils = gpxParse.utils;

const metersInOneMile = 1609.34;

let waypoints = [];

const { promises: { readFile } } = require("fs");
const path = require("path");

// const gpxFile = '../data/rivm_20240502_drinkwaterkranen.gpx';
// const gpxSet = '20240502Drinkwaterkaart';
const gpxFile = '../data/rivm_drinkwaterkranen_actueel_20250302.json';
const gpxSet = '20250302Drinkwaterkaart';

let isValidNumber = function (n) {
    return n != -1 && n != 0;
}
let getWptsInRange = async function (lat, lon, maxRangeMeters, maxWpts) {
    if (waypoints.length == 0) {
        await loadWaypoints();
    }
        // console.log("Current directory:", __dirname);

        // let wptsstring = "";
        // await readFile(path.resolve(__dirname, gpxFile)).then(fileBuffer => {
        //     // console.log(fileBuffer.toString());
        //     wptsstring = fileBuffer.toString();
        // }).catch(errohttps://data.rivm.nl/geo/alo/wfs?request=GetFeature&service=WFS&version=1.1.0&outputFormat=application%2Fjson&typeName=alo:rivm_drinkwaterkranen_actueelr => {
        //     console.error(error.message);
        // });

        // gpxParse.parseGpx(wptsstring, n
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

let loadWaypoints = async function() {
    console.log("Current directory:", __dirname);

        //let wpts = [];
        let wptsstring = "";
        await readFile(path.resolve(__dirname, gpxFile)).then(fileBuffer => {
            // console.log(fileBuffer.toString());
            wptsstring = fileBuffer.toString();
        }).catch(error => {
            console.error(error.message);
        });

        // TODO file1/file2 as backup
        let ext = path.extname(gpxFile); 
        if (ext == '.gpx') {
            
             await gpxParse.parseGpx(wptsstring, function (error, data) {
                //do stuff
                waypoints = data.waypoints;
                // todo load in sqllite
            });
        } else if (ext = '.json') {
            waypoints = extractWaypoints(wptsstring);
        }
}

let extractWaypoints = function(json) {
    let wpts = []; // .lat .lon
    try {
        var data = JSON.parse(json);
        for (const element of data.features) { 
            //console.log(element);
             
            wpts.push( {
                "lat" : element.properties.latitude,
                "lon" : element.properties.longitude,
            })            
        }
        
    } catch(err) {
        console.log(err);
    }
    return wpts;
}

exports.initialize = function () {
    loadWaypoints().then(function (response) {
        console.log("Loaded: " + waypoints.length + " waypoints");        
      })    
}

exports.getInRange = async function (lat, lon, maxRangeMeters, maxWpts) {

    return await getWptsInRange(lat, lon, maxRangeMeters, maxWpts);
}