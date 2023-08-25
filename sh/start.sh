#!/usr/bin/env bash

set -e

HASH="########################"
LINE="=========================="
IFS=$'\t'
red=$'\033[1;31m'
green=$'\e[32m'
NC=$'\033[0m'

# Export environment variables in the config.env file
DIR="$(cd "$(dirname "$0")" && pwd)"

source $DIR/config.env

cd ${AdvancedKDB}

startTP="q tick.q ${Sym_File} ${TP_Log} -p ${TP_PORT} -t ${Tick_Timer} </dev/null >> ${Log_Dir}/tick.log 2>&1 &"
#startTP="q tick.q tick/sym.q . -p 5010 -t 1000 1>> ${AdvancedKDB}/logs/tick.log 2>&1 &"
startRDB="q ${RDB_Dir}/rdb_taq.q :${TP_PORT} -p ${RDB_TAQ_PORT} </dev/null >> ${Log_Dir}/rdb_taq.log 2>&1 &"
startAGG="q ${RDB_Dir}/rdb_agg.q :${TP_PORT} -p ${RDB_AGG_PORT} </dev/null >> ${Log_Dir}/rdb_agg.log 2>&1 &"
startFH="q tick/feed.q :${TP_PORT} -p ${FH_PORT} </dev/null >> ${Log_Dir}/feedhandler.log 2>&1 &"
startCEP="q tick/cep.q :${TP_PORT} -p ${CEP_PORT} </dev/null >> ${Log_Dir}/cep.log 2>&1 &"

if [ -z $1 ]; then
	echo "No arguments supplied..."
	echo "Please re-run script along with one of the following options:"
	echo "[1] \"all\" to start all tickerplant processes"
	echo "[2] (\"tick\", \"rdb\", \"agg\", \"feed\", \"cep\") to start individual processes."
	echo ""
	echo "NOTE: \"rdb\" corresponds to the Trade and Quote (TAQ) RDB process."
	echo "Exiting..."
	exit 0
fi

confirmExit () {
        read -e -p "You have chosen to exit. Are you sure? [Y/N] " CONFIRM
        if [ "${CONFIRM^^}" == "Y" ]; then
                echo "Exiting..."
                exit 0
        fi
}

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

RUN=0
while [[ $RUN -eq 0 ]]; do
	if [[ "$@[*]" =~ "all" ]]; then
		echo "${HASH} TickerPlant Start ${HASH}"
		echo ""
		echo ""
		echo ""
		read -p "You have chosen to start all processes. Do you wish to continue? [Y/N] " EXIT
		if [ "${EXIT^^}" == "N" ]; then
			confirmExit
		elif [ "${EXIT^^}" == "Y" ]; then
			echo "${LINE}${LINE}${LINE}"
			echo "${HASH} Starting All Processes ${HASH}"
			echo "${LINE}${LINE}${LINE}"
			echo ""
			echo ""
			echo "Starting Tickerplant: "
			echo $startTP
			eval $startTP
			echo ""
                        echo ""
			echo "Starting RDB (Trade and Quote): "
			echo "$startRDB"
			eval $startRDB
			echo ""
                        echo ""
			echo "Starting RDB (Aggregation): "
			echo "$startAGG"
			eval $startAGG
			echo ""
                        echo ""
			echo "Starting Feedhandler: "
			echo "$startFH"
			eval $startFH
			echo ""
                        echo ""
			echo "Starting Complex Event Processor (CEP): "
			echo "$startCEP"
			eval $startCEP
			echo ""
                        echo ""
			sleep 1
			# Find PIDs of running processes
			RUN=1
		else 
			echo "$EXIT is not a valid input. Please choose [Y/N] for Yes or No."
		fi
	else
		echo "You have chosen to start the following processes: ($@)"
		read -p "Do you wish to continue with your selection? [Y/N] " EXIT
		if [ "${EXIT^^}" == "N" ]; then
			confirmExit
		elif [ "${EXIT^^}" == "Y" ]; then
			if [[ "$@[*]" =~ "tick" ]]; then
				echo ""
				echo "Starting Tickerplant: "
				echo "$startTP"
				eval $startTP
			fi
                        if [[ "$@[*]" =~ "rdb" ]]; then
				echo ""
				echo "Starting RDB (Trade and Quote): "
                                echo "$startRDB"
                                eval $startRDB
                        fi
                        if [[ "$@[*]" =~ "agg" ]]; then
				echo ""
				echo "Starting RDB (Aggregation): "
                                echo "$startAGG"
                                eval $startAGG
                        fi
                        if [[ "$@[*]" =~ "feed" ]]; then
                                echo ""
			       	echo "Starting Feedhandler: "
                                echo "$startFH"
                                eval $startFH
                        fi
                        if [[ "$@[*]" =~ "cep" ]]; then
				echo ""
				echo "Starting Complex Event Processor (CEP): "
                                echo "$startCEP"
                                eval $startCEP
                        fi
 			RUN=1
		else
			echo "${EXIT} is not a valid input. Please choose from [Y/N]."
		fi
	fi
done


# Find PIDs of running processes
tickPID=$(ps -ef | grep -v grep | grep "tick.q"|grep "${TP_PORT}" |awk '{print $2}')
rdbPID=$(ps -ef | grep -v grep | grep "rdb_taq.q"|grep "${RDB_TAQ_PORT}" |awk '{print $2}')                        
aggPID=$(ps -ef | grep -v grep | grep "rdb_agg.q"|grep "${RDB_AGG_PORT}" |awk '{print $2}')                        
fhPID=$(ps -ef | grep -v grep | grep "feed.q"|grep "${FH_PORT}" |awk '{print $2}')                        
cepPID=$(ps -ef | grep -v grep | grep "cep.q"|grep "${CEP_PORT}" |awk '{print $2}')                        
checkIfRunning "$tickPID" "Tickerplant"                        
checkIfRunning "$rdbPID" "RDB (Trade and Quote)"                       
checkIfRunning "$aggPID" "RDB (Aggregation)"                       
checkIfRunning "$fhPID" "Feedhandler"                        
checkIfRunning "$cepPID" "Complex Event Processor (CEP)"
