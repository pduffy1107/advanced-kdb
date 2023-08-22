// Load logging.q and sym.q
system "l ",getenv[`AdvancedKDB],"/log/logging.q";
system "l ",getenv[`AdvancedKDB],"/tick/sym.q";

args:.Q.opt .z.x;

tpDate:(raze args[`date]);
tpLog:`$(raze args[`dir]);

upd:insert

// Generates a list of all log files in the TPLog directory.
files:system "find ",string[tpLog],"/ -maxdepth 1 -type f";

files:`$":",'files;

// Get the dates log file
logFile:files[where like[string files;"*",raze string tpDate]];

.log.out["Replaying log file: ",raze string logFile]

-11!logFile 0

hdbDir:`$":",getenv[`AdvancedKDB],"/db/hdb/";

.log.out["Saving tables to HDB disk."]
saveHDB: .Q.hdpf[`.;hdbDir;"D"$tpDate;`sym] each tables[];

// Creates a nested list of all tables and corresponding columns to be compressed
columnMatrix:`$(raze string[hdbDir],string[tpDate],"/"),/:/: (string[tables[]],/:' ("/",/:'string ((cols each tables[]) except\: `time`sym)));

.log.out["Beginning HDB Column Compression"]

HDBCompression:{[column] a:"/" vs string column;
	colName:a[-1 + count a];
	preComp:(key -21!column); 							// Get filesize of column before compression
	-19!(column;column;17;2;6);							// Beginning compression
	postComp:(key -21!column);							// Get filesize of column after compression
	$[not postComp~preComp; 							// Check that preComp and postComp do not match. If they match, no compression took place.
		(::); 
		.log.err["Column \"",colName,"\" could not be compressed. Please investigate. Size before compression: ",raze string preComp,"; Size after compression: ",raze string postComp]];
	}

(@'/:)[HDBCompression;columnMatrix]
.log.out["HDB writedown and compression process complete. Exiting eod.q..."]
exit 0

