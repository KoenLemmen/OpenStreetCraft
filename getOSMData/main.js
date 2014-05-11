// usage : node main.js 6.563243099999999 46.518709099999995
var osmread = require('osm-read');
var fs = require('fs');

var OUTPUT_JSON = 'data/OSMData.json';

if (process.argv.length < 4) {
    console.log('usage : node main.js 6.563243099999999 46.518709099999995');
    return;
}

var DEG_TO_METER = 111111;
var ONE_METER = 0.000009; // number of deg in a meter
var SQUARE_SIZE = 500; // meters

var longitude = parseFloat(process.argv[2]);
var latitude = parseFloat(process.argv[3]);

var minLongitude = longitude - ONE_METER * SQUARE_SIZE;
var maxLongitude = longitude + ONE_METER * SQUARE_SIZE;

var minLatitude = latitude - ONE_METER * SQUARE_SIZE;
var maxLatitude  = latitude + ONE_METER * SQUARE_SIZE;

var OSM_DATA_BLOB = {
    longitude : longitude,
    latitude  :latitude,
    minLatitude : minLatitude,
    maxLatitude : maxLatitude,
    minLongitude : minLongitude,
    maxLongitude : maxLongitude,
    way : [],
    node : {},
    bounds : []
};

osmread.parse({
    url: 'http://www.overpass-api.de/api/xapi?way[bbox=' + minLongitude+ ',' + minLatitude + ',' + maxLongitude + ',' + maxLatitude + ']',
    format: 'xml',
    endDocument: function() {
        writeJson(JSON.stringify(OSM_DATA_BLOB));
    },
    bounds: function(bounds){
        OSM_DATA_BLOB.bounds.push(bounds);
    },
    node: function(node){
        node.lon = (node.lon - minLongitude) * 111111 | 0;
        node.lat = (node.lat - minLatitude) * 111111 | 0;
        OSM_DATA_BLOB.node[node.id] = node;
    },
    way: function(way){
        OSM_DATA_BLOB.way.push(way);
    },
    error: function(msg){
        console.error('error: ' + msg);
    }
});

function writeJson(json) {
    fs.writeFile(OUTPUT_JSON, json, function(err) {
        if(err) {
            console.log(err);
        } else {
            console.log("The file was saved as: "+OUTPUT_JSON);
        }
    }); 
}