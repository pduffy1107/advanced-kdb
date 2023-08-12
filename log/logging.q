// Script tasked with logging events in Tick processes

\d .log

// Convert data type to string (unless already a string)
str:{$[10=abs type x;(::);string]x};

// Get details of the calling process
details:{"USER: ",str .z.u,"; HANDLE: ",str .z.w,"; MEM: ",str .Q.w[]}

// Normal log writeout
out:{[x](neg 1)@ string[.z.p],"| ",.log.details[],"| INFO: ",str x};

// Error log writeout
err:{[x](neg 2)@ string[.z.p],"| ",.log.details[],"| ERROR: ",str x};


// Connection Opened
//.z.po:{.log.out[raze[("Connection opened on Handle ",str .z.w]};

// Connection Closed
//.z.pc:{.log.out[raze[("Connection closed on Handle ",str .z.w]};
