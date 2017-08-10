#!/bin/bash

# TrelloStatsToCSV.sh
# Short, specific script that will read the json store for my Trello stats and output as csv
# It will output a card, stard and end which are the minimal fields to create kanban analysis graphs
#
# Primary target for this is for an Excel stats tool for Throughput, Cycle time and WIP from
# https://github.com/FocusedObjective/FocusedObjective.Resources


if [ -z "$1" ]; then echo "Usage: ./TrelloStatsToCSV.sh (jsonfile)"; exit; fi

# Simple data convert
#jq -r '. | map([.id,.start,.end] | @csv) | join("\n")' $1

# Data convert specific for the Throughput, Cycle-time and WIP from FocusedObjective
jq -r '. | map([.end,.start,"",.id,.name] | @csv) | join("\n")' $1
