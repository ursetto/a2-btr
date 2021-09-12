#!/usr/bin/python

# Read bytes from SRC, XOR each with the lower 8 bits of the current file position,
# and write them to DEST. This implements the unscrambling algorithm for Below the Root
# files on Side A (and works in reverse).

import argparse

ap = argparse.ArgumentParser(description='Swizzle (unscramble or scramble) file SRC to DEST.')
ap.add_argument('src')
ap.add_argument('dest')
args = ap.parse_args()

src = open(args.src, "rb")
pos = 0

buf = bytearray(src.read())
for i, b in enumerate(buf):
    buf[i] = b ^ pos
    pos = (pos + 1) & 0xff   # src.tell() % 256 also works

dest = open(args.dest, "wb")
dest.write(buf)
