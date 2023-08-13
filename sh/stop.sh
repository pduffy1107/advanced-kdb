#!/usr/bin/env bash

set -e

HASH="########################"
LINE="======================="

# Export environment variables in the config.env file
DIR="$(cd "$(dirname "$0")" && pwd)"

source $DIR/config.env

cd ${AdvancedKDB}

# Find PIDs of running processes
tickPID=$(ps -ef | grep -v grep | grep "tick.q"|grep "${TP_PORT}" |awk '{print $2}')
rdbPID=$(ps -ef | grep -v grep | grep "tick.q"|grep "${RDB_TAQ_PORT}" |awk '{print $2}')
aggPID=$(ps -ef | grep -v grep | grep "tick.q"|grep "${RDB_AGG_PORT}" |awk '{print $2}')
fhPID=$(ps -ef | grep -v grep | grep "tick.q"|grep "${FH_PORT}" |awk '{print $2}')
cepPID=$(ps -ef | grep -v grep | grep "tick.q"|grep "${CEP_PORT}" |awk '{print $2}')

# If no arguments passed, then exit
if [ -z $1 ]; then
        echo "No arguments supplied..."
        echo "Please re-run script along with one of the following options:"
        echo "[1] \"all\" to stop all tickerplant processes"
        echo "[2] (\"tick\", \"rdb\", \"rdbagg\", \"feed\", \"cep\") to stop individual processes."
        echo "\n"
        echo "NOTE: \"rdb\" corresponds to the Trade and Quote (TAQ) RDB process."
        echo "Exiting..."
        exit 0
fi

# Exit Procedure
confirmExit () {
        read -e -p "You have chosen to exit. Are you sure? [Y/N] " CONFIRM
        if [ "$CONFIRM" == "Y" ]; then
                echo "Exiting..."
                writeLog "Exit option chosen. Exiting addCMTP.sh..."
                exit 0
        fi
}

# Stopping Processes function
stopProcess () {
	if ! [[ -z "$1" ]]; then
		read -e -p "$2 is a currently running process. Do you wish to stop this process? [Y/N] " STOP
		if [[ "${STOP^^}" == "Y" ]]; then
			kill -9 $1
			echo "$2 is no longer running."
			echo "$LINE"
		else
			read -p "Do you wish to exit? [Y/N] " EXIT
			if [[ "${EXIT^^}" == "Y" ]]; then
				confirmExit
			fi
		fi
	else
		echo "$2 is not a running process. Skipping..."
	fi	
}

RUN=0
while [[ $RUN -eq 0 ]]; do
	if [[ "$@[*]" =~ "all" ]]; then
		read -p "You have chosen to stop ALL processes. Are you sure you wish to continue? [Y/N] " CONTINUE
		if [[ ${CONTINUE^^} == "Y" ]]; then
			stopProcess "$tickPID" "Tickerplant"
			stopProcess "$rdbPID" "RDB (Trade and Quote)"
			stopProcess "$aggPID" "RDB (Aggregation)"
			stopProcess "$fhPID" "Feedhandler"
			stopProcess "$cepPID" "Complex Event Processor (CEP)"
			RUN=1
		else
			confirmExit
		fi
	else
                echo "You have chosen to stop the following processes: ($@)"
                read -p "Do you wish to continue with your selection? [Y/N] " EXIT
                if [ "${EXIT^^}" == "Y" ]; then
                        confirmExit
                else
                        if [[ "$[*]" =~ "tick" ]]; then
	                	stopProcess "$tickPID" "Tickerplant"
                        fi
                        if [[ "$@[*]" =~ "rdb" ]]; then
                                stopProcess "$rdbPID" "RDB (Trade and Quote)"
                        fi
                        if [[ "$@[*]" =~ "aggrdb" ]]; then
                                stopProcess "$aggPID" "RDB (Aggregation)"
                        fi
                        if [[ "$@[*]" =~ "feed" ]]; then
                                stopProcess "$fhPID" "Feedhandler"
                        fi
                        if [[ "$@[*]" =~ "cep" ]]; then
                                stopProcess "$cepPID" "Complex Event Processor (CEP)"
                        fi
                        RUN=1
                fi
        fi
done

