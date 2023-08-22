h: neg hopen hsym `$":localhost:5010"

// Load logging script
system "l ",getenv[`AdvancedKDB],"/log/logging.q"

// Update function.
// Insert data (d) into table (t)
upd:{[t;d]
        if[t in tables[];							// If table exists 
                checkTable[t;d];						// check the data integrity
                insert[t;d];							// insert data into corresponding trade/quote table
		updAggTbl[];							// Aggregate the data in the aggTbl table
		@[neg[h];(`.u.upd; `agg; flip get each aggTbl); h"::"]		// Send the aggregated data back to TP
		];
        };

// Aggregation Table Function.
// Convert trade/quote values into Aggregation table
// Schema: agg:([] time:"n"$(); sym:`$(); minPx:"f"$(); maxPx:"f"$(); minBid:"f"$(); maxBid:"f"$(); minAsk:"f"$(); maxAsk:"f"$(); volume: "j"$(); ToB:"f"$());
updAggTbl:{aggTrade:: select minPx: min px, maxPx: max px, volume:sum[px*sz] by sym from trade;
	aggQuote:: select minBid: min bid, maxBid: max bid, minAsk: min ask, maxAsk: max ask, ToB:max[bid] - min[ask] by sym from quote;
	aggTbl:: `time`sym xcols update time:.z.N from 0!aggTrade lj aggQuote;}


// Datatype checker Function
// If data is not in table format, convert to table
checkTable:{[t;d] 
        if[not (type d) in 98 99h;
                schema: key flip value t;
                d: $[0>type first d;
                        enlist schema!d;
                        flip schema!d];];
        };


if[not "w"=first string .z.o;system "sleep 1"];


// Retrieve TP and HDB ports
.u.x: .z.x,(count .z.x)_(":5010";":5012");

// Initialise schema
.u.rep:{.log.out["Initialising schemas from Tickerplant."];
        (.[;();:;].)each x;                                     // x is a list of two-item lists, each containing a table name (as a symbol) and an empty schema for that table.
        if[null first y;:()];                                   // y, is a single two-item list, where the last element is the TP logfile and the first element is the number of 
                                                                //      messages written to this logfile so far. If 'first y' is empty, no new messages have been written to log
        .log.out["Replaying log file."];
        -11!y;                                                  // Replay appropriate number of messages from the start of the TP logfile
        system "cd ",1_-10_string first reverse y};

.u.rep .(hopen`$":",.u.x 0)"((.u.sub[`trade;`];.u.sub[`quote;`]);`.u `i`L)";

