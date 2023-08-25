// Load logging script
system "l ",getenv[`AdvancedKDB],"/log/logging.q";

.u.x:.z.x,(count .z.x)_(":5010";":5012");

h:neg hopen`$":localhost",.u.x 0;

syms:`MSFT.O`IBM.N`GS.N`BA.N`VOD.L; 	/stocks

px:syms!45.15 191.10 178.50 128.04 341.30; 	/starting prices 
n:2;						/number of rows per update
flag:1; 					/generate 10% of updates for trade and 90% for quote

movement:{[t] rand[0.0001]*px[t]}; 		/get a random price movement 

// Generate trade price
getprice:{[t] px[t]+:rand[1 -1]*movement[t]; px[t]}; 
getbid:{[t] px[t]-movement[t]}; 			/generate bid price
getask:{[t] px[t]+movement[t]}; 			/generate ask price

// Timer function to publish data
.z.ts:{
	s:n?syms;
	.log.out["Publishing new data to Tickerplant."];
	$[0<flag mod 10;
		h(".u.upd";`quote;(n#.z.N;s;getbid'[s];getask'[s];n?1000;n?1000)); 
		h(".u.upd";`trade;(n#.z.N;s;getprice'[s];n?1000))];
	flag+:1;}

// Trigger timer every second
\t 1000
