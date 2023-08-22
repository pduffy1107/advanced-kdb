import pykx as kx
import csv
import pandas as pdi
from argparse import ArgumentParser
import configparser
import asyncio
import sys
import os

parser = ArgumentParser()
parser.add_argument("-f", "--file", dest="filename",
                    help="filepath for CSV to be publishd to TP", metavar="FILE")
parser.add_argument("-t", "--table", dest="tablename",
                    help="Table that CSV file is to be published to (e.g. trade, quote)")

args = parser.parse_args()

file_path=str(args.filename)
table_name=str(args.tablename)

if not os.path.exists(file_path):
    print("Path of the file is Invalid")
    exit()

if not file_path.lower().endswith(".csv"):
    print("File is not CSV.")
    exit()

if table_name.lower()=="trade":
    q_table=kx.q.read.csv(file_path, types="NSFJ")
elif table_name.lower()=="quote":
    q_table=kx.q.read.csv(file_path, types="NSFFJJ")
else:
    print("This table is not supported. Only trade and quote tables can be published using this script.")
    exit()

TP_PORT=int(os.environ["TP_PORT"])

async def publish(table, data):
    async with kx.AsyncQConnection("localhost", TP_PORT, username="PyKX-Client") as q:
        res = q(".u.upd",str(table), data)
        return res

for i in range(len(q_table)):
    asyncio.run(publish(table=table_name, data=kx.q.value(q_table[i])))

print("Published "+str(i+1)+" rows to Tickerplant.")

exit()
