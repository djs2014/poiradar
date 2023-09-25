// http server (reverse proxy on antagonist)
const http = require("http");

const poi = require('./services/poi.js');
// const fs = require('fs/promises');
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

        // TODO
        // authorization
        if (!req.headers.authorization) {
            res.writeHead(401);
            res.end("Unauthorized");
            console.log('Unauthorized');
            return;
        }

        let allowed = await apikeys.validApikey(req.headers.authorization);
        if (!allowed) {
            res.writeHead(403);
            res.end("Forbidden");
            console.log('Forbidden');
            return;
        }

         // lat, lon must exist
        if (!req.query.lat || !req.query.lon) {
            res.writeHead(400);
            res.end("Bad request");
            console.log('Bad request');
            return;
        }

        let lat = parseFloat(req.query.lat);
        let lon = parseFloat(req.query.lon);

        // default poi set waterpunt poi @@TODO        
        let maxRangeMeters = 10000;
        if (req.query.maxRange) {
            maxRangeMeters = parseInt(req.query.maxRange);
        }
        let maxWpts = 100;
        if (req.query.maxWpts) {
            maxWpts = parseInt(req.query.maxWpts);
        }


        res.writeHead(200, { 'Content-Type': 'application/json' });
                 res.end(JSON.stringify(await poi.getInRange(lat, lon,
                     maxRangeMeters, maxWpts)));

    } catch (err) {
        res.writeHead(500);
        res.end(err.message);
    }
});


http.createServer(app)
    .listen(port, function (req, res) {
        console.log("Server started at port " + port);
    });
