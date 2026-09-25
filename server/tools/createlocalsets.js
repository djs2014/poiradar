const fs = require('fs/promises');
const path = require('path');

const OVERPASS_ENDPOINT = 'https://overpass-api.de/api/interpreter';

function getOutputFileName(region) {
    return path.resolve(
        __dirname,
        `../data/OSM_${region}_${new Date().getFullYear()}.geojson`
    );
}
const queries = [
    {"name":`PYR`, "query":`[out:json][timeout:60];nwr["amenity"~"^(toilets|drinking_water)$"](41.157802,-1.712877,44.684111,4.950330);out tags center;` },
    {"name":`ALP`, "query":`[out:json][timeout:60];nwr["amenity"~"^(toilets|drinking_water)$"](45.112135,5.954345,48.410817,12.617553);out tags center;`},
    {"name":`NL`, "query":`[out:json][timeout:60];nwr["amenity"~"^(toilets|drinking_water)$"](50.049592,3.025890,53.971792,7.552257);out tags center;`},    
]

function toFeature(element) {
	const latitude = element.lat ?? element.center?.lat;
	const longitude = element.lon ?? element.center?.lon;

	if (latitude == null || longitude == null) {
		return null;
	}

	return {
		type: 'Feature',
		properties: {
			osm_id: element.id,
			osm_type: element.type,
			...element.tags
		},
		geometry: {
			type: 'Point',
			coordinates: [longitude, latitude]
		}
	};
}

async function createLocalSet(idx = 0) {    
	const response = await fetch(OVERPASS_ENDPOINT, {
		method: 'POST',
		headers: {
			'Accept': 'application/json',
			'Content-Type': 'application/x-www-form-urlencoded',
			'User-Agent': 'GarminConnectIQ_POIradar_Sets/2.0'
		},
		body: new URLSearchParams({ data: queries[idx].query }),
		signal: AbortSignal.timeout(600000) // 10 minutes
	});

	if (!response.ok) {
		throw new Error(`Overpass request failed with HTTP ${response.status}`);
	}

	const data = await response.json();
	const features = data.elements.map(toFeature).filter(Boolean);
	const geoJson = {
		type: 'FeatureCollection',
		features
	};

	await fs.writeFile(getOutputFileName(queries[idx].name), `${JSON.stringify(geoJson, null, 2)}\n`);
	console.log(`Saved ${features.length} features to ${getOutputFileName(queries[idx].name)}`);
}

for (let i = 0; i < queries.length; i++) {
    createLocalSet(i).catch(error => {
        console.error(`Unable to create local set for ${queries[i].name}: ${error.message}`);
        process.exitCode = 1;
    });
}
