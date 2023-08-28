// Load logging.q
system "l ",getenv[`AdvancedKDB],"/log/logging.q"

tpLog:`$.z.x[0];

// Generates a list of all log files in the TPLog directory.
files:system "find ",string[tpLog],"/ -maxdepth 1 -type f"
files:`$":",'files

// Filter for the symbol we're looking for
filter:`$.z.x[1];

// Generate new Log file
newLogFile: .[`$string[tpLog],"_",string filter; (); :; ()];
newLogHandle: hopen hsym newLogFile;

// Redefine update such that it appends new log file with trade data containing the symbol desired
upd:{[table;data]

	if[(table=`trade) and (any filter in/: flip data);						// If row contains "trade" schema and symbol in row...
        newLogHandle enlist (`upd;table;flip (flip data) where filter in/: flip data)];		// update new Log file with filtered data. 
    };

// Replay all logs in the TP Log directory.
{-11!x} each files

