#!/usr/bin/env bash

set -e

HASH="########################"
LINE="=========================="
IFS=$'\t'


# Export environment variables in the config.env file
DIR="$(cd "$(dirname "$0")" && pwd)"

source $DIR/config.env

cd ${AdvancedKDB}

startTP="q tick.q ${Sym_File} ${TP_Log} -p ${TP_PORT} -t ${Tick_Timer} </dev/null >> ${Log_Dir}/tick.log 2>&1 &"
#startTP="q tick.q tick/sym.q . -p 5010 -t 1000 1>> ${AdvancedKDB}/logs/tick.log 2>&1 &"
startRDB="q ${RDB_Dir}/rdb_taq.q :${TP_PORT} -p ${RDB_TAQ_PORT} </dev/null >> ${Log_Dir}/rdb_taq.log 2>&1 &"
startAGG="q ${RDB_Dir}/rdb_agg.q :${TP_PORT} -p ${RDB_AGG_PORT} </dev/null >> ${Log_Dir}/rdb_agg.log 2>&1 &"
startFH="q tick/feed.q -p ${FH_PORT} </dev/null >> ${Log_Dir}/feedhandler.log 2>&1 &"
startCEP="q tick/cep.q -p ${CEP_PORT} </dev/null >> ${Log_Dir}/cep.log 2>&1 &"

if [ -z $1 ]; then
	echo "No arguments supplied..."
	echo "Please re-run script along with one of the following options:"
	echo "[1] \"all\" to start all tickerplant processes"
	echo "[2] (\"tick\", \"rdb\", \"rdbagg\", \"feed\", \"cep\") to start individual processes."
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
			echo "All Processes have started successfully."
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
                        if [[ "$@[*]" =~ "aggrdb" ]]; then
				echo ""
				echo "Starting RDB (Aggregation): "
                                echo "$startAGGRDB"
                                eval $startAGGRDB
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
