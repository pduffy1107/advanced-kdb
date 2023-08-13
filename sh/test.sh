#!/usr/bin/env bash

set -e

HASH="########################"
LINE="======================="
red=$'\033[1;31m'
green=$'\e[32m'
NC=$'\033[0m'
IFS=$'\n'

# Export environment variables in the config.env file
DIR="$(cd "$(dirname "$0")" && pwd)"

source $DIR/config.env

# Find PIDs of running processes
tickPID=$(ps -ef | grep -v grep | grep "tick.q"|grep "${TP_PORT}" |awk '{print $2}')
rdbPID=$(ps -ef | grep -v grep | grep "rdb_taq.q"|grep "${RDB_TAQ_PORT}" |awk '{print $2}')
aggPID=$(ps -ef | grep -v grep | grep "rdb_agg.q"|grep "${RDB_AGG_PORT}" |awk '{print $2}')
fhPID=$(ps -ef | grep -v grep | grep "feed.q"|grep "${FH_PORT}" |awk '{print $2}')
cepPID=$(ps -ef | grep -v grep | grep "cep.q"|grep "${CEP_PORT}" |awk '{print $2}')

# Check if PID is running function
checkIfRunning () {
	# If the PID is greater than zero, the Process must be running
	if [[ $1 -gt 0 ]]; then
		echo "${2} is ${green}RUNNING${NC} on PID: $1"
	# If the PID is not greater than zero, the process must not be running
	else
		echo "${2} is ${red}NOT RUNNING${NC}."
	fi
}

checkIfRunning "$tickPID" "Tickerplant"
checkIfRunning "$rdbPID" "RDB (Trade and Quote)"
checkIfRunning "$aggPID" "RDB (Aggregation)"
checkIfRunning "$fhPID" "Feedhandler"
checkIfRunning "$cepPID" "Complex Event Processor (CEP)"
