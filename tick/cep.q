h: neg hopen hsym `$":localhost:5010"


// Update function.
// Insert data (d) into table (t)
upd:{[t;d]
        $[t in tables[];
                checkTable[t;d];
                insert[t;d];
		aggTbl[];
		@[neg[h];(`.u.upd; `agg; flip get each agg); h"::"]
		];
        };

// Aggregation Table Function.
// Convert trade/quote values into Aggregation table
// Schema: agg:([] time:"n"$(); sym:`$(); minPx:"f"$(); maxPx:"f"$(); minBid:"f"$(); maxBid:"f"$(); minAsk:"f"$(); maxAsk:"f"$(); volume: "j"$(); ToB:"f"$());
aggTbl:{aggTrade:: select minPx: min px, maxPx: max px, volume:sum[price*size] by sym from trade;
	aggQuote:: select minBid: min bid, maxBid: max bid, minAsk: min ask, maxAsk: max ask, ToB:max[bid] - min[ask] by sym from quote;
	aggTbl:: `time`sym xcols update time:.z.N from 0!aggTrade lj aggQuote;}


// Datatype checker Function
// If data is not in table format, convert to table
checkTable:{[t;d] 
        $[not (type d) in 98 99h;
                schema: key flip value t;
                d: $[0>type first d;
                        enlist schema!d;
                        flip schema!d];];
        };


if[not "w"=first string .z.o;system "sleep 1"];


// Retrieve TP and HDB ports
.u.x: .z.x,(count .z.x)_(":5010";":5012");

// Initialise schema
.u.rep:{(.[;();:;].)each x;if[null first y;:()];};

.u.rep .(hopen`$":",.u.x 0)"((.u.sub[`trade;`];.u.sub[`quote;`]);`.u `i`L)";

.z.ts:{

