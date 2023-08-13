/2019.06.17 ensure sym has g attr for schema returned to new subscriber
/2008.09.09 .k -> .q
/2006.05.08 add

\d .u
// Initilisation Dictionary
// This table holds what symbols each subscriber receives (i.e. where to publish each symbol)
init:{w::t!(count t::tables`.)#()}

// Function to delete subscribers from subscriber table
del:{w[x]_:w[x;;0]?y};.z.pc:{del[;x]each t};

// Select function
// Select symbols that each subscriber requests
sel:{$[`~y;
	x;
	select from x where sym in y]}

// Publish function
// Publishes data to each subscriber
pub:{[t;x]
	{[t;x;w]
		if[count x:sel[x]w 1;
			(neg first w)(`upd;t;x)]
		}[t;x]each w t}

// Addition (Append) function
// Add subscriber to .u.w and return table name and table data to subscriber.
add:{
	$[(count w x)>i:w[x;;0]?.z.w;
		.[`.u.w;(x;i;1);union;y]
		;w[x],:enlist(.z.w;y)];
	(x;$[99=type v:value x;
		sel[v]y;
		@[0#v;`sym;`g#]]
		)
	}

// Subscription Function
// When a process attempts to subscribe to the TP, add them to .u.w
sub:{
	if[x~`; 				// if no tables are passed, subscribe to all tables
		:sub[;y]each t];
	if[not x in t;				// if table does not exist, return an error
		'x];
	del[x].z.w;add[x;y]}			// Remove client from .u.w if already there and re-add with symbols


// End function
// Tell subscribers to run EOD
end:{(neg union/[w[;;0]])@\:(`.u.end;x)}

