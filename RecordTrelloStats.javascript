


if (process.env.UBER_STATS_DB_PATH === undefined) {
	console.log("UBER_STATS_DB_PATH is not set. Exiting.");
	return;
}

var fs = require('fs');
var os = require('os');
var newdata = JSON.parse(fs.readFileSync('/tmp/Ubersicht.Trello.widget.data', 'utf8'));
var db = JSON.parse(fs.readFileSync(process.env.UBER_STATS_DB_PATH, 'utf8'));
var listIds = process.env.UBER_STATS_LISTS.split(',');
var today = new Date().toISOString().substring(0,10);


newdata.forEach(function(item, index) {
	if (listIds.indexOf(item.idList) > -1) {
		if (db[item.id] == null) {
			db[item.id] = {id: item.id, name: item.name, start: today, end: null}
		}
		else {
			db[item.id].name = item.name; // Just updated the name if it exists
		}

		if (item.idList == process.env.UBER_STATS_DONE && db[item.id].end == null) {
			db[item.id].end = today;
		}
	}
});

var output = JSON.stringify(db);
fs.writeFileSync(process.env.UBER_STATS_DB_PATH, output);



