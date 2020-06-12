#!/usr/bin/env python

import xml.etree.ElementTree as ET
import os
import sys
import csv

if len(sys.argv) < 2:
    print("USAGE: ./xlifftocsv.py xlifffile")
    exit(1)

tree = ET.parse(sys.argv[1])
head, _ = os.path.splitext(sys.argv[1])
with open(head + '.csv', 'w') as outfile:
    xlsxwriter = csv.writer(outfile)
    xlsxwriter.writerow(["file","id","note","English","Arabic"])
    root = tree.getroot()
    for child in root:
        file_column = child.attrib['original']
        for unit in child.iter('{urn:oasis:names:tc:xliff:document:1.2}trans-unit'):
            id_column = unit.attrib['id']
            english_column = unit.find('{urn:oasis:names:tc:xliff:document:1.2}source').text
            note_column = unit.find('{urn:oasis:names:tc:xliff:document:1.2}note').text
            arabic_column = unit.find('{urn:oasis:names:tc:xliff:document:1.2}target')
            if arabic_column is not None:
                arabic_column = arabic_column.text
            else:
                arabic_column = ''
            xlsxwriter.writerow([file_column, id_column, note_column, english_column, arabic_column])
