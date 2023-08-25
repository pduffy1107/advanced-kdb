web_port:getenv[`WEB_PORT]

system "l ",getenv[`AdvancedKDB],"/log/logging.q"

if[not system"p";.log.out["No port set. Setting port to ",web_port]; system"p ",web_port];

.z.ws:{neg[.z.w] .j.j @[getTrades;`$x]};
.z.wc: {delete from `subs where handle=x; delete from `.web.openConns where handle=x};
.z.wo:{`.web.openConns upsert (x;.z.N)};

.web.openConns:([] handle: (); time:"n"$())

/* table definitions */
trade:flip `time`sym`px`sz!"nsfj"$\:();

/* subs table to keep track of current subscriptions */
subs:2!flip `handle`func`params!"is*"$\:();

/* functions to be called through WebSocket */
loadPage:{ getSyms[.z.w]; sub[`getTrades;enlist `]};
filterSyms:{ sub[`getTrades;x]};

getSyms:{ (neg[x]) .j.j `func`result!(`getSyms;distinct (trade`sym))};

/*subscribe to something */
sub:{`subs upsert(.z.w;x;enlist y)};

RDB_PORT:getenv[`RDB_TAQ_PORT]

rdb:hopen `$"::",RDB_PORT

getTrades:{
        filter:$[all raze null x;distinct trade`sym;raze x];
        res: $[11h=abs type filter;rdb({select from trade where sym in x};filter);rdb({select from trade};`)];
        `func`result!(`getTrades;res)
        };
