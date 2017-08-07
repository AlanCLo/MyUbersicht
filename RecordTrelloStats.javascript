/*
 * Record script for Trellow Dashboard
 * ==== 
 * An auxiliary script that is executed with every Trello Dashboard update.
 * The purpose is to capture new and updated data into a data store.
 * 
 * Follows Lean Kanban concepts and implements:
 * - Frequent snapshot of board status to automate input for metrics. Frequency determined by Dashboard refresh
 * - Captures at minimum: Start and end dates per card to allow CFD, run charts and other analysis
 * - Only looks between columns that processes work, from committed to done (as defined by UBER_STATS_LISTS)
 *
 * The store should expand indefinitely and no items are deleted. 
 * It is possible to miss cards that move through the columns and are archived before this script is executed. 
 * Archiving cards is necessary because there is a Trello limit and warning that you have to many cards.
 * 
 */


if (process.env.UBER_STATS_DB_PATH === undefined) {
	console.log("UBER_STATS_DB_PATH is not set. Exiting.");
	return;
}

var fs = require('fs');
var os = require('os');

// Fetch state data
var newdata = JSON.parse(fs.readFileSync('/tmp/Ubersicht.Trello.widget.data', 'utf8'));
var db = JSON.parse(fs.readFileSync(process.env.UBER_STATS_DB_PATH, 'utf8'));
var listIds = process.env.UBER_STATS_LISTS.split(',');
var today = new Date().toISOString().substring(0,10);


newdata.forEach(function(item, index) {
	if (listIds.indexOf(item.idList) > -1) {
		// Card is in a list to be counted. Ensure there is a record in the store
		if (db[item.id] == null) {
			// New card because its not in our store, add!
			// Doesn't matter which column, as long as it is in one of the accepted lists
			// This is because we are just observing a snapshot
			db[item.id] = {id: item.id, name: item.name, start: today, end: null}
		}
		else {
			// Item exists, just do an update of the card		
			db[item.id].name = item.name; 
		}

		// If the card has been marked done, set the date if it isn't already set
		if (item.idList == process.env.UBER_STATS_DONE && db[item.id].end == null) {
			db[item.id].end = today;
		}
	}
});

// Write results
var output = JSON.stringify(db);
fs.writeFileSync(process.env.UBER_STATS_DB_PATH, output);



