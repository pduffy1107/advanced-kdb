// Call sym file
/q tick.q SRC [DST] [-p 5010] [-o h]
system"l tick/",(src:first .z.x,enlist"sym"),".q"

// Load u.q and logging.q
\l tick/u.q
\l log/logging.q`

if[not system"p";.log.out["No port set. Setting port to 5010"; system"p 5010"]

\d .u

// Loading function.
// Defines the log output file for the current day
ld:{if[not type key L::`$(-10_string L),string x;
		.[L;();:;()]];
	i::j::-11!(-2;L);
	// Returns error if the log file is corrupted
	if[0<=type i;
		.log.err[(string L)," is a corrupt log. Truncate to length ",(string last i)," and restart"];
		exit 1];
	// Open handle to log file
	.log.out["Opening handle to log file: ", .log.str L];
	hopen L};

// Tick function
// Initialises the tables as defined in sym.q
tick:{init[];
	if[not min(`time`sym~2#key flip value@)each t;
		'`time`sym];
	// Applies the group attribute on sym columns
	@[;`sym;`g#]each t;
	d::.z.D;
	// Runs load function (opening handle to log file)
	if[l::count y;
		L::`$":",y,"/",x,10#"."
		;l::ld d]};

// End-Of-Day (EOD) function.
// Runs the EOD process, Increase daycount, close handle to current day logs
endofday:{.log.out["Beginning EOD..."];
	end d;
	d+:1;
	if[l;hclose l;
		l::0(`.u.ld;d)]};

// Timer function.
// Checks if EOD has occurred and if so calls EOD function

ts:{if[d<x;
	if[d<x-1;
		system"t 0";
		.log.error["more than one day?"]];
	endofday[]]};

// Batch mode
// If Ticker Timer is active, enable periodic publishing to subscribers

if[system"t"; .log.out["Enabling Batch Mode..."];
	// Publish data to subscribers
	.z.ts:{pub'[t;value each t];
		@[`.;t;@[;`sym;`g#]0#];
		i::j;
		ts .z.D}; 			// check for EOD
	// Update function, which inserts data (x) into table (t)
 	upd:{[t;x]
 		if[not -16=type first first x;
			if[d<"d"$a:.z.P;
				.z.ts[]];
				a:"n"$a;
				x:$[0>type first x;a,x;(enlist(count first x)#a),x]];
		t insert x;
		if[l;
			l enlist (`upd;t;x);
			j+:1];
		}];

// Non-batch mode

if[not system"t"; .log.out["Enabling Non-Batch Mode..."];
	system"t 1000";
 	.z.ts:{ts .z.D};
 	upd:{[t;x]ts"d"$a:.z.P;				// Update table (t) with data (x)
 		if[not -16=type first first x;
			a:"n"$a;
			x:$[0>type first x;
				a,x;
				(enlist(count first x)#a),x]];
 		f:key flip value t;
		
		pub[t;					// Publish data to subscriber
			$[0>type first x;
			enlist f!x;
			flip f!x]];
		if[l;
			l enlist (`upd;t;x);
			i+:1];
		}];



// Initialise TickerPlant

\d .
.u.tick[src;.z.x 1];

\
 globals used
 .u.w - dictionary of tables->(handle;syms)
 .u.i - msg count in log file
 .u.j - total msg count (log file plus those held in buffer)
 .u.t - table names
 .u.L - tp log filename, e.g. `:./sym2008.09.11
 .u.l - handle to tp log file
 .u.d - date
