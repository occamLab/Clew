#!/usr/bin/env python

import csv
import sys
import os

if len(sys.argv) < 2:
    print("USAGE: ./csvtostrings.py csvfile")
    exit(1)

f_handles = {}

with open(sys.argv[1]) as f:
    reader = csv.reader(f)
    for row in reader:
        source_file = row[0]
        dest_filename = os.path.basename(source_file) + ".translated"
        if dest_filename not in f_handles:
            f_handles[dest_filename] = open(dest_filename, 'wt')
            print("opened " + dest_filename)
        f_handles[dest_filename].write('"' + row[1] + '" = "' + row[4].replace('"', r'\"') + '";\n')
