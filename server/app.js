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

        let maxRangeMeters = req.query.maxRange ? parseInt(req.query.maxRange) : 10000;
        let maxWpts = req.query.maxWpts ? parseInt(req.query.maxWpts) : 100;

        // 3. Resolve data FIRST before writing headers
        const useOverpass = req.query.poiSet === '1';

        let data;
        if (useOverpass) {
            data = await overpass.getInRange(lat, lon, maxRangeMeters, maxWpts);
        } else {
            data = await poi.getInRange(lat, lon, maxRangeMeters, maxWpts);
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
