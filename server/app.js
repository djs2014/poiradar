// http server (reverse proxy on antagonist)
const http = require("http");

const poi = require('./services/poi.js');
const overpass = require('./services/overpass.js');

const compression = require('compression');
const apikeys = require('./helpers/apikeys.js');

// Express for handling GET and POST request
const express = require("express");
const app = express();
const port = process.env.PORT || 4000;

const shouldCompress = (req, res) => {
    if (req.headers['x-no-compression']) {
        return false;
    }
    return compression.filter(req, res);
};

function safeParseInt(input, fallback = 0) {
  const parsed = parseInt(input, 10);
  return Number.isNaN(parsed) ? fallback : parsed;
}

app.use(compression({
    filter: shouldCompress,
    threshold: 0
}));

app.get('/favicon.ico', (req, res) => res.status(204).end());

app.get("/", async function (req, res) {
    res.writeHead(200, { 'Content-Type': 'text/plain' });
    var message = 'It works!\n',
        version = 'yes'; //'NodeJS ' + process.versions.node + '\n',
    response = [message, version].join('\n');
    res.end(response);
});

app.get("/poi", async function (req, res) {

    try {
        const queryString = req.originalUrl.split('?').splice(1).join('?');
        console.log('Process poi: ' + queryString);

        // authorization
        if (!req.headers.authorization) {
            console.log('Unauthorized');
            return res.status(401).send("Unauthorized");
        }

        let allowed = await apikeys.validApikey(req.headers.authorization);
        if (!allowed) {
            console.log('Forbidden');
            return res.status(403).send("Forbidden");
        }

        // lat, lon must exist
        if (!req.query.lat || !req.query.lon) {
            console.log('Bad request');
            return res.status(400).send("Bad request");
        }

        let lat = parseFloat(req.query.lat);
        let lon = parseFloat(req.query.lon);

        let maxRangeMeters = safeParseInt(req.query.maxRange, 10000);
        let maxWpts = safeParseInt(req.query.maxWpts, 100);

        // Resolve data FIRST before writing headers


        // 0 = RIVM waterpoints (default)
        // 1 = OSM set (overpass)
        // 2 = OSM waterpoints
        // 3 = OSM toilets
        // 4 = File OSM ALP
        // 5 = File OSM PYR
        // 6 = File OSM NL
        let poiSet = safeParseInt(req.query.poiSet, 0);
        
        const useOverpass = (poiSet === 1 || poiSet === 2 || poiSet === 3);

        let data;
        if (useOverpass) {
            data = await overpass.getInRange(lat, lon, maxRangeMeters, maxWpts, poiSet);
        } else {
            data = await poi.getInRange(lat, lon, maxRangeMeters, maxWpts, poiSet);
        }

        // Send response safely (Express res.json handles headers + stringify)
        return res.json(data);

    } catch (err) {
        console.error('Error in /poi handler:', err);

        // Guard against writing headers twice if headers were already sent
        if (!res.headersSent) {
            return res.status(500).send(err.message);
        }
    }
});


http.createServer(app)
    .listen(port, function (req, res) {
        console.log("Server started at port " + port);
        poi.initialize();
    });
