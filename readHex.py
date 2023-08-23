#!/usr/bin/python3
import sys
with open(sys.argv[1]) as file:
    for line in file:
        # loop over space-delimited strings
        val = []
        for hex in line.split():
            val.append(float.fromhex(hex))
            # print(float.fromhex(line.rstrip()))
        print(*val)