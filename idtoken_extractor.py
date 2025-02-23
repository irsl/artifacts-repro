#!/usr/bin/env python3

import glob
import os
import re
import sys

FOUND = set()

def process_file(filepath):
    with open(filepath, "rb") as fh:
        data = fh.read()

    pos = 0
    pat = re.compile(rb'ey[a-zA-Z0-9_-]{20,}\.ey[a-zA-Z0-9_-]{80,}\.[a-zA-Z0-9_-]{150,}')
    while m := pat.search(data, pos):
        pos = m.start() + 1
        token = m.group(0)
        if token in FOUND:
            continue
        FOUND.add(token)
        print(filepath, ":", file=sys.stderr)
        print(token.decode())
        print("", file=sys.stderr)
        

def do_the_job(directory):
    for f in glob.glob(os.path.join(directory, "*.dump")):
        process_file(f)
    

if __name__ == "__main__":
    do_the_job(*sys.argv[1:])
