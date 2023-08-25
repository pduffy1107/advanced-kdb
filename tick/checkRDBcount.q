rdb:hopen `$"::",getenv[`RDB_TAQ_PORT];
\t 1000

.z.ts:{
	0N!"Trade: ",raze string rdb"count trade";
	0N!"Quote: ",raze string rdb"count quote"}

