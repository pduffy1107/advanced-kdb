import pykx as kx
import csv
import pandas as pdi
from argparse import ArgumentParser
import configparser
import asyncio
import sys
import os

# Import Argument Parser for Filepath and Table Name
parser = ArgumentParser()
parser.add_argument("-f", "--file", dest="filename",
                    help="filepath for CSV to be publishd to TP", metavar="FILE")
parser.add_argument("-t", "--table", dest="tablename",
                    help="Table that CSV file is to be published to (e.g. trade, quote)")

args = parser.parse_args()

file_path=str(args.filename)
table_name=str(args.tablename)

# Pre-flight checks: 
# - Check filepath exists. 
# - Check file is CSV.
# - Check table name is valid
# - Ensure number of columns match expected value
# - Ensure no columns are wholly null

if not os.path.exists(file_path):
    print("Path of the file is Invalid")
    exit()

if not file_path.lower().endswith(".csv"):
    print("File is not CSV.")
    exit()

with open(file_path,'r') as f:
    reader=csv.reader(f, delimiter=',')
    ncol = len(next(reader))

if table_name.lower()=="trade":
    if ncol!=4:
        print("Trade CSV's column number does not equal 4 (time, sym, px, sz). Please check file integrity and retry.")
        exit()
    else:
        datatype="NSFJ"
        q_table=kx.q.read.csv(file_path, types=datatype)
elif table_name.lower()=="quote":
    if ncol!=6:
        print("Quote CSV's column number does not equal 6 (time, sym, bid, ask, bsize, asize). Please check file integrity and retry.")
        exit()
    else:
        datatype="NSFFJJ"
        q_table=kx.q.read.csv(file_path, types=datatype)
else:
    print("This table is not supported. Only trade and quote tables can be published using this script.")
    exit()

null_in_table=kx.q.where(kx.q.all(kx.q.null(q_table))).py()

if null_in_table:
    print("Null columns in table: ")
    print(*null_in_table, sep="\n")
    print("Please investigate and retry. (Remember trade and quote columns are of type \"NSFJ\" and \"NSFFJJ\" respectively).")
    exit()

# Read in TP_PORT environment variable so we can connect to the Tickerplant.
TP_PORT=int(os.environ["TP_PORT"])

# Asynchronous publishing function. "table" = Table Name (string). "data" = q Table (PyKX Table).
async def publish(table, data):
    # Open Asynchronous connection to TP
    async with kx.AsyncQConnection("localhost", TP_PORT, username="PyKX-Client") as q:
        for i in range(len(data)):
            # Asynchronously call u.upd with table name and publish one row of data. Repeat for each row in the table.
            q(".u.upd",str(table), kx.q.value(data[i]))
        await q
        return i

i=asyncio.run(publish(table=table_name, data=q_table))

print("Published "+str(i+1)+" rows to Tickerplant.")

exit()
