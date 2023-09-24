const { promises: { readFile } } = require("fs");
const path = require("path");
const apikeyfile = '../keys/apikeys.json';

let apikeys = {};
let isValidApikey = async function (apikey) {
    if (!apikeys.keys) {
        console.log("Current directory:", __dirname);

        let json = {};
        await readFile(path.resolve(__dirname,apikeyfile)).then(fileBuffer => {
            // console.log(fileBuffer.toString());
            json = fileBuffer.toString();
        }).catch(error => {
            console.error(error.message);
        });
        apikeys = JSON.parse(json);
    }
    return apikeys.keys.indexOf(apikey) > -1;
}

exports.validApikey = async function (apikey) {   
    return await isValidApikey(apikey);
}