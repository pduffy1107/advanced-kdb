// Load logging.q and sym.q
system "l ",getenv[`AdvancedKDB],"/log/logging.q"
system "l ",getenv[`AdvancedKDB],"/tick/sym.q"

args:.Q.opt .z.x

csvFile:`$(raze ":",args[`csv]);
tableName:`$(raze args[`table]);

// Check csv file exists
$[-11h=type key csvFile;.log.out["File exists."];.log.err["Filepath for CSV is incorrect. File does not exist. Please input correct filepath for csv."]];

// Check extension is csv
$["csv" like ((count string csvFile)-3)_string csvFile;.log.out["File extension is csv."]; [.log.err["File is not csv."]; exit 1]];

tp:@[hopen;"J"$getenv[`TP_PORT]; {0}];

// For future reference, how to check if file/folder exists 
/q)b:key `:sampleData/trade.csv
/q)type b
/-11h						file exists if result type is -11h (symbol atom)

/q)c:key `:sampleData/agg.csv
/q)type c
/0h						file/folder does not exist if type is 0h (empty general list)

/q)d:key `:sampleData/
/q)type d
/11h						folder does exist if type is 11h (symbol list)


upload:{[table;csvFilePath] .log.out["Ingesting csv file in preparation for upload."];
	$[table=`trade;datatypes:"NSFJ";datatypes:"NSFFJJ"];							// Check table name for correct column datatypes
	table upsert flip value flip (datatypes; enlist csv) 0: hsym csvFilePath;				// Ingest csv data into local table
	.log.out["Uploading table ",raze string table," to Tickerplant."];
	neg[tp](".u.upd";table;value flip get each table);							// push data to TP
	.log.out["Upload successful."]};

// check if tableName in tables
$[tableName in tables[]; upload[tableName;csvFile];.log.err["Table ",raze string[`tableName]," not in TickerPlant schema."]];

// Once job is done, exit
exit 0
