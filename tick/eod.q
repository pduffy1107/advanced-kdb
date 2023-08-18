// Load logging.q and sym.q
system "l ",getenv[`AdvancedKDB],"/log/logging.q"
system "l ",getenv[`AdvancedKDB],"/tick/sym.q"

args:.Q.opt .z.x

tpDate:"D"$(raze ":",args[`date]);
tpLog:`$(raze args[`dir]);


// Update function.
// Insert data (d) into table (t)
upd:{[t;d]
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

// Generates a list of all log files in the TPLog directory.
files:system "find ",string[tpLog],"/ -maxdepth 1 -type f"

files:`$":",'files

// Get the dates log file
logFile:files[where like[string files;"*",raze string tpDate]]

saveHDB: .Q.hdpf[`.;`:db/hdb;tpDate;`sym] each tables[`.];

hdbDir:`:db/hdb

compressHDB:{



