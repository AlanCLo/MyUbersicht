#!/bin/bash

# TrelloStatsToCSV.sh
# Short, specific script that will read the json store for my Trello stats and output as csv
# It will output a card, stard and end which are the minimal fields to create kanban analysis graphs

if [ -z "$1" ]; then echo "Usage: ./TrelloStatsToCSV.sh (jsonfile)"; exit; fi

jq -r '. | map([.id,.start,.end] | @csv) | join("\n")' $1
