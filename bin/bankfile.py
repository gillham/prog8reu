#!/usr/bin/env python3

with open("load.bin", "wb") as outf:
    for i in range(0, 32):
        for j in range(0, 32):
            for k in range(0, 256):
                outf.write(k.to_bytes(1))

