/q tick/r.q [host]:port[:usr:pwd] [host]:port[:usr:pwd]
/2008.09.09 .k ->.q

// Load logging.q
system "l ",getenv[`AdvancedKDB],"/log/logging.q"

tpLog: hsym `$raze string[getenv[`TP_Log]]

s:`$.z.x[0]

NewLog: hsym `$raze string[getenv[`Log_Dir],"/tp_",string s,"_log"

NewLogHandle: hopen NewLog


