import pykx as kx
import pandas as pd
from argparse import ArgumentParser
import configparser
import sys
import os

parser = ArgumentParser()
parser.add_argument("-f", "--file", dest="filename",
                    help="filepath for CSV to be publishd to TP", metavar="FILE")

args = parser.parse_args()

file_path=str(args.filename)

if not os.path.exists(file_path):
    print("Path of the file is Invalid")
    exit()

if not file_path.lower().endswith(".csv"):
    print("File is not CSV.")
    exit()

df=pd.read_csv(file_path)

print(df.head(10))
