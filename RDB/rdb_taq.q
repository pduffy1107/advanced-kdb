/q tick/r.q [host]:port[:usr:pwd] [host]:port[:usr:pwd]
/2008.09.09 .k ->.q

// Load logging.q
system "l ",getenv[`AdvancedKDB],"/log/logging.q"

// Update function.
// Insert data (d) into table (t)
upd:{[t;d] MC+:1;
	if[t in tables[];
		checkTable[t;d];
		insert[t;d]];
	};


// Datatype checker Function
// If data is not in table format, convert to table
checkTable:{[t;d] 
	if[not (type d) in 98 99h;
		schema: key flip value t;
		d: if[0>type first d;
			enlist schema!d;
			flip schema!d];];
	};

if[not "w"=first string .z.o;system "sleep 1"];

// get the ticker plant and history ports, defaults are 5010,5012
.u.x:.z.x,(count .z.x)_(":5010";":5012");

// end of day: save, clear, hdb reload
.u.end:{.log.out["Beginning EOD Process..."];
	t:tables`.;						// Return a list of the names of all tables defined in the default namespace, assign to the local variable t
	t@:where `g=attr each t@\:`sym;				// Obtains the subset of tables in t that have the grouped attribute on their sym column. 
	.log.out["Applying grouped attribute on sym columns."];
	.Q.hdpf[`$":",.u.x 1;`:.;x;`sym];			// .Q.hdpf is a high-level function which saves all in-memory tables to disk in partitioned format, 
								// 	empties them out and then instructs the HDB to reload.
	@[;`sym;`g#] each t;					// Applies the g attribute to the sym column of each table
	};

// init schema and sync up from log file;cd to hdb(so client save can run)
// .u.rep takes two arguments.
.u.rep:{.log.out["Initialising schemas from Tickerplant."];
	(.[;();:;].)each x;					// x is a list of two-item lists, each containing a table name (as a symbol) and an empty schema for that table.
	if[null first y;:()];					// y, is a single two-item list, where the last element is the TP logfile and the first element is the number of 
								//	messages written to this logfile so far. If 'first y' is empty, no new messages have been written to log
	.log.out["Replaying log file."];
	-11!y;							// Replay appropriate number of messages from the start of the TP logfile
	system "cd ",1_-10_string first reverse y};		// Change current directory of RDB to root of on-disk partitioned database so .Q.hdpf writes to correct directory
/ HARDCODE \cd if other than logdir/db


// connect to ticker plant for (schema;(logcount;log))
// hopen `$":",.u.x 0 	- 	obtain the location of TP process and pass to hopen
// "((.u.sub[`;`]       -	Through TP process handle, obtain updates for tables (".u.sub[`;`]" for all tables or ".u.sub[`t;`]" for table t)
// "`.u `i`L"		- 	Obtain name/location of TP logfile and number of messages written by TP to said logfile.
.u.rep .(hopen `$":",.u.x 0)"((.u.sub[`quote;`];.u.sub[`trade;`]);`.u `i`L)";
