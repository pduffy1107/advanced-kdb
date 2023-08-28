# Advanced KDB

KX Project for completion of the 'Advanced KDB' CMTP. This project focuses on tick architecture in kdb/q. In this repo a unique system including tickerplant, RDBs, feedhandler,  complex event processor, csv batch uploader and more were constructed. This CMTP tests all areas of kdb but also other coding language including Python and Bash.

This document outlines the tasks undertaken as part of completing the project, as well as how an end-user can run the system.


## Question 1

Assuming you have cloned this repository to your local environment, please change directory to the ```advanced-kdb``` directory. From here you can view the ```config.env``` file which contains important environment variables for running the Tick system. Please feel free to change these variables to what suits your system (keep in mind defaults are included in the q scripts if these variables are left undefined).

### Configuration options

| **Environment Variable** | **Default Value**          | **Description**                                                                                                           |
|--------------------------|----------------------------|---------------------------------------------------------------------------------------------------------------------------|
| ```AdvancedKDB```        | ```"$(pwd)"```             | The home directory of the Advanced KDB project. The config.env file should be sourced from the 'advanced-kdb' directory.  |
| ```Log_Dir```            | ```${AdvancedKDB}/logs```  | The directory where all log files for running processes are stored ('advanced-kdb/logs').                                 |
| ```RDB_Dir```            | ```${AdvancedKDB}/RDB```   | The directory where all RDB process are located ('advanced-kdb/RDB').                                                     |
| ```TP_Log```             | ```${AdvancedKDB}/tplog``` | The directory containing the replay logs for the tickerplant ('advanced-kdb/tplog').                                      |
| ```Sym_File```           | ```"sym"```                | The name of the sym file contained in 'advanced-kdb/tick'.                                                                |
| ```Tick_Timer```         | ```"1000"```               | The time in milliseconds for each tick to occur in tick.q.                                                                |
| ```TP_PORT```            | ```5010```                 | The port on which the Tickerplant process runs.                                                                           |
| ```RDB_TAQ_PORT```       | ```5011```                 | The port on which the Trade and Quote RDB process runs.                                                                   |
| ```RDB_AGG_PORT```       | ```5012```                 | The port on which the Aggregation RDB process runs.                                                                       |
| ```FH_PORT```            | ```5013```                 | The port on which the Feedhandler process runs.                                                                           |
| ```CEP_PORT```           | ```5014```                 | The port on which the Complex Event Processor runs.                                                                       |
| ```WEB_PORT```           | ```5018```                 | The port on which the RDB Gateway process for the HTML Websocket connection runs.                                         |

#### Startup

Once you are happy with the above environment variables, from the ```advanced-kdb``` directory run:
```
source sh/config.env
```

All Tickerplant processes (Tick, RDBs, Feedhandler and CEP) can be started by running:
```
sh/start.sh all
```

Alternatively, you can start up individual processes by selecting the from the following options:

- ```tick``` - Tickerplant process.
- ```rdb``` - RDB (Trade and Quote schema).
- ```agg``` - RDB (Aggregation schema).
- ```feed``` - Feedhandler process.
- ```cep``` - Complex Event Processor.

```
sh/start.sh [OPTIONS]

sh/start.sh tick rdb fh
```
To shut processes down, run either:
```
sh/stop.sh all

sh/stop.sh [OPTIONS]
```
### Exercise 1 - Ticker Plant

The Tickerplant process is quite similar to the default found in kdb-tick Git repository. The process loads in the ```sym.q``` file which contains the schemas for the tickerplant - Trade, Quote and Aggregation.
```
// Define the Trade, Quote and Aggregation Tables
trade:([] time:"n"$(); sym:`$(); px:"f"$(); sz:"j"$());

quote:([] time:"n"$(); sym:`$(); bid:"f"$(); ask: "f"$(); bsize:"j"$(); asize:"j"$());

agg:([] time:"n"$(); sym:`$(); minPx:"f"$(); maxPx:"f"$(); minBid:"f"$(); maxBid:"f"$(); minAsk:"f"$(); maxAsk:"f"$(); volume: "f"$(); ToB:"f"$());
```
It also loads the ```u.q``` script which contains subscription and publishing functions.
The Tickerplant initialises by loading the empty schemas as defined in  ```sym.q``` while also defining the log output file for the current day (contained in ```advanced-kdb/tplog/```).<br>
Every timer tick (1000ms as defined in ```config.env```) the tickerplant publishes any updates to the schema tables to the relevant subscribers and updates the tplog with new information.

We call the Tickerplant process in ```sh/start.sh``` as follows:
```
q tick.q ${Sym_File} ${TP_Log} -p ${TP_PORT} -t ${Tick_Timer} </dev/null >> ${Log_Dir}/tick.log 2>&1 &
```
Here, we point tick.q to the correct sym file and tplog directory. We set the port to ```$TP_PORT``` and tick timer to ```$Tick_Timer```.

```</dev/null``` redirects the standard output (```stdout```) to ```/dev/null``` which discards it to ```${Log_Dir}/tick.log```. 

```2>&1``` redirects the standard error (```stderr```) to ```stdout```. Since ```stdout``` is being directed to ```/dev/null```, both standard output and standard error are being directed to the log output file located at ```${Log_Dir}/tick.log```

Finally, the ```.sub``` namespace is tasked with keeping track of subscribers to the TP process. ```.sub.conns``` is a table of open connections on the process. In order to update the logs every minute with subscriber handles and message counts, a manual timer ```.sub.timer``` is tasked with comparing ```.z.t``` (current time) with the startup time. When the difference between ```.z.t``` and ```.sub.globalTimer``` is greater than 60000ms (1 minute), the function executes ```.sub.publishDetails``` which writes message count and subscriber handles to the log output.

### Exercise 2 - RDB

This task required two separate RDB processes which subscribed to different tables. RDB 1 or RDB_TAQ subscribes to the Trade And Quote schemas, while RDB 2 or RDB_AGG subscribes to the Aggregation schema. When the RDBs initialise, they retrieve the desired schemas from the Tickerplant and replay an appropriate number of log messages since their last update.

In an effort to prevent any awry messages from going to the wrong RDBs, both RDB processes are set up with a filter called ```checkTable``` in their ```upd``` functions. ```upd``` will first check that the message is from a table that the RDB has loaded in. Then the ```checkTable``` function checks that the message is in a table/dictionary format before allowing the message to be inserted into the table.

```
q ${RDB_Dir}/rdb_taq.q :${TP_PORT} -p ${RDB_TAQ_PORT} </dev/null >> ${Log_Dir}/rdb_taq.log 2>&1 &
```

The process is started much the same as the tickerplant, defining ```TP_PORT``` as the desired port connection, setting the RDB port as appropriate and finally writing logs out to the ```advanced-kdb/logs/``` directory.

### Exercise 3 - Feed Handler

This sample feedhandler simply pumps semi-random data to the tickerplant for the RDB to retrieve down the line. The feedhandler only supplies Trade and Quote data, as the Complex Event Processor will handle Aggregation data.

```.z.ts``` is set to 1000ms and tasked with calling the TP's update function and supplying the TP with newly-created dummy data.

The feedhandler is once again called similarly to the other processes:

```
q tick/feed.q :${TP_PORT} -p ${FH_PORT} </dev/null >> ${Log_Dir}/feedhandler.log 2>&1 &
```

where ```TP_PORT``` is the Tickerplant port and ```FH_PORT``` is the Feedhandler port.

### Exercise 4 - Complex Event Processor
The Complex Event Processor works like both an RDB and a Feedhandler. The CEP is tasked with ingesting trade and quote data, combining the tables into an aggregation table and feeding the data back to the Tickerplant. The script contains many of the same functions as the RDB processes, including ```.u.rep``` for replaying log files, ```.u.sub``` for subscribing to trade and quote table and ```upd``` updating tables with new information. 

```upd``` not only contains the ```checkTable``` function for validating messages, but also calls a new function ```updAggTbl```. This function, as the name suggests, aggregates the data from the trade and quote tables into one table. The ```upd``` function then pushes this newly-built table to the Tickerplant for the Agg RDB.

Again, the function is called in ```sh/start.sh``` via:

```
q tick/cep.q :${TP_PORT} -p ${CEP_PORT} </dev/null >> ${Log_Dir}/cep.log 2>&1 &
```

### Exercise 5 Logging

Logging is very important for debugging issues with any software system. For this project, ```advanced-kdb/log/logging.q``` is loaded into nearly every q script. It contains functions which write to standard output, as well as standard error. 

Good logging includes details of the process, including user details, port handles, memory profiles and informative messaging. This script also includes definitions for ```.z.po``` and ```.z.pc``` (Port Open and Port Closed). Every time a connection is made or closed, it is written to ```stdout```. In the case of the Tickerplant, ```.sub.conns``` is updated with open connection information, and similarly information is deleted once the connection is closed.

### Exercise 6 Startup/Shutdown Scripts

These scripts have been references in previous sections, in particular the startup script. Below is a breakdown of scripts. Both ```start.sh``` and ```stop.sh``` take the arguments ```(all tick rdb agg feed cep)```

#### start.sh
The start script first sources its variables from the ```config.env``` file, located in the same directory: ```advanced-kdb/sh```. From there, the startup commands as described in each previous section are defined for evaluation further down the line.

Two functions are defined: ```confirmExit``` and ```checkIfRunning```. The former is a confirmation script in the case the user wishes to cancel the command. The latter function checks for PIDs matching the startup commands and is explained further in ```test.sh```.

The startup script evaluates startup processes based on the inputs from the user. If "all" is provided to the input, then the script starts all processes. Similarly, if only "tick" is provided, then the script will only start the Tickerplant process. Invalid values will return an error message.

#### stop.sh

Similarly to ```start.sh```, ```stop.sh``` takes input values defined above. The script searches running processes which match the names of the q scripts and their corresponding port. Below is an example for the tickPID.

```
tickPID=$(ps -ef | grep -v grep | grep "tick.q"|grep "${TP_PORT}" |awk '{print $2}')
```
Once found, the script will prompt the user if they wish to stop this particular process. If confirmed, the script kills the command:

```
if [[ "${STOP^^}" == "Y" ]]; then
    kill -9 $tickPID
    echo "Tickerplant is no longer running."
```

#### test.sh

This script confirms to the user that all processes have started up correctly by searching ```ps -ef``` for processes matching the script and port details. An example for the Tickerplant is shown below.

```
tickPID=$(ps -ef | grep -v grep | grep "tick.q"|grep "${TP_PORT}" |awk '{print $2}')
```

If the PID value is greater than zero, then the process is expected to be running and a confirmation message is outputted to the system:

```
if [[ $1 -gt 0 ]]; then
    echo "${2} is ${green}RUNNING${NC} on PID: $1"
```

### Exercise 7 - Tickerplant Log Replay

The Tickerplant logs are located in the ```advanced-kdb/tplog``` directory:

```
pduffy1_kx_com@advanced-kdb:~/advanced-kdb$ ls -lt tplog/
total 93736
-rw-r----- 1 pduffy1_kx_com pduffy1_kx_com 42050391 Aug 25 20:16 sym2023.08.25
-rw-r----- 1 pduffy1_kx_com pduffy1_kx_com 23321269 Aug 22 15:37 sym2023.08.22
```

The ```logReplay.q``` script reads in a tickerplant log directory which contains updates from trade and quote data, and rewrites to a log file only containing data for a specific symbol. Both the location of the tickerplant log file and the filter symbol should be provided by the user.

In the below example, the appropriate way to call this script is outlined:

```
q tick/logReplay.q tplog IBM.N
```

where tplog is the director for TP output logs and IBM.N is the symbol on which to be filtered.

The filtering is achieved by redefining ```upd``` such that when `-11!` is called on the TP log files, it checks if the table is trade, and if so ensures that the desired symbol is in the table. Once filtered, the script writes the updated table to a new TP Log file named after the filtered symbol (e.g. `tplog_IBM.N`) to the home directory.

### Exercise 8 - CSV File load

```csvUpload.q``` is a batch upload process where q reads in a CSV file locally to a table and then uploads that table to the Tickerplant. The script loads in the sym.q file found in ```tick/sym.q``` but could as well be loaded by initiliasing the schemas from the Tickerplant.

To run the process, simply run:

```
q tick/csvUpload.q -csv <CSV FILE PATH> -table <TABLE NAME>
```
```
q tick/csvUpload.q -csv sampleData/trade.csv -table trade
```

This script runs a number of checks to confirm:

- The CSV file exists.
- The File has the CSV extenstion.
- The Table Name is loaded locally.

To demostrate this script, a pair of 200-row CSV files for trade and quote schema were created in the ```sampleData``` subdirectory:

- `sampleData/trade.csv`
- `sampleData/quote.csv`

### Exercise 9 - EOD

This script runs an EOD process on TP Log files by loading the contents locally, writing them to disk in date-partitioned format and compressing all columns except the `time` and `sym` columns. ```tick/eod.q``` takes two arguments: `-date` and `-dir` which are Date in `YYYY.MM.DD` format and subdirectory containing the tplogs.

The EOD script should be called as follows:
```
q tick/eod.q -date <YYYY.MM.DD> -dir <TP LOG DIR> </dev/null> >> ${Log_Dir}/eod.log 2>&1 &
```
```
q tick/eod.q -date 2023.08.22 -dir tplog </dev/null> >> ${Log_Dir}/eod.log 2>&1 &
```

The script contains checks to confirm that the columns were compressed post-writedown and will output an error message to `eod.log` if compression fails. The script writes the partition to ```advanced-kdb/db/hdb```.

### Exercise 10 - Schema Change Runbook

Details on the Schema Change runbook can be found in `runbook/schemaChange.txt`

## Part 2 - Debugging

The solutions to the Debugging portion of this project are contained in the `debugging` subdirectory.

## Part 3 - API

### Exercise 1 - PyKX

Leveraging KX's newest Python library makes light work of uploading data to a Tickerplant. The Python script is located under ```advanced-kdb/API/PyKX/publish.py```. To start the upload process run:
```
python3 API/PyKX/publish.py -t <TABLE_NAME> -f <FILE_PATH>
```
```
python3 API/PyKX/publish.py -t trade -f sampleData/trade.csv
```

The script functions very similarly to the `csvUpload.q` script written early, with some subtle differences. There are more pre-flight checks:

- Check File Path exists.
- Check file extension is CSV.
- Check Table Name is valid. 
- Ensure column number matches expected value.
- Ensure no columns are null (in case datatypes are incorect).

Once checks are cleared, the Python script establishes an Asynchronous connection to the Tickerplant and initiates a for loop. With each iteration of the loop, the PyKX script publishes one row of data to the TP.

### Exercise 2 - HTML

Before starting the HTML webpage, you must start the `filterSym.q` script. The websocket port is hardcoded in the HTML script and so must be edited to ensure it matches the `$WEB_PORT` defined in `sh/config.env`. To compare, run:

```
cat API/HTML/websockets.html | grep "localhost:"
```
```
echo $WEB_PORT
```
and observe the outputs. Edit the HTML script to point to the correct port.

To start `filterSym.q`, run the following command:

```
q API/HTML/filterSym.q -p ${WEB_PORT} &
```

`filterSym.q` script is a gateway process to RDB TAQ. It opens a connection to the RDB process and whenever it receives input from the websocket, it will query the RDB with the following statement:
```
select from trade where sym=x
```
where `x` is the symbol on which to filter.

The response from `filterSym.q` is a JSON encoded table, which HTML formats into a table to display on the webpage.
