// Script tasked with logging events in Tick processes

\d .log

// Convert data type to string (unless already a string)
str:{$[10=abs type x;(::);string]x};


out:{[x](neg 1)@ string[.z.p],"|",str x};
err:{[x](neg 2)@ string[.z.p],"|",str x};


// Connection Opened
//.z.po:

// Connection Closed
//.z.pc:
