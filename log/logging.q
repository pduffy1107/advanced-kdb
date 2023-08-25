// Script tasked with logging events in Tick processes

// Convert data type to string (unless already a string)
.log.str:{$[10=abs type x;(::);string]x};

// Normal log writeout
												// Changing format of memory profile to be more reader-friendly:
												// "used:359600 | heap:67108864 | peak:67108864 | wmax:0 | mmap:0....
.log.out:{-1 string[.z.p],"| USER: ",.log.str[.z.u],"; HANDLE: ",.log.str[.z.w],"| INFO: ",.log.str[x],"; MEM: ",ssr[ssr[.Q.s[.Q.w[]]; "| "; ":"];"\n";" | "]};

// Error log writeout
.log.err:{-2 (string[.z.p],"| USER: ",.log.str[.z.u],"; HANDLE: ",.log.str[.z.w],"| ERROR: ",.log.str[x],"; MEM: ",ssr[ssr[.Q.s[.Q.w[]]; "| "; ":"];"\n";" | "])};


// Connection Opened
.z.po:{$[`conns in key`.sub;`.sub.conns upsert (.z.u;.z.w;.z.h;.z.p);::];
	.log.out[raze[("Connection opened on Handle ",raze string .z.w)]]};

// Connection Closed
.z.pc:{$[`conns in key`.sub;delete from `.sub.conns where user=.z.u;::];
	.log.out[raze[("Connection closed on Handle ",raze string .z.w)]]};
