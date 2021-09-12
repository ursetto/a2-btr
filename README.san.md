# Below the Root san inc ProDOS port

Quick notes on the port.

It crashes when starting any game other than the default character (Neric).

`LOADER.SYSTEM` loads `BELOW.THE.ROOT` at $0800-$0BC5 using ProDOS MLI calls and jumps to $0800.



`BELOW.THE.RT.1` contains what may be a full image of the two BTR sides. I see a bit of unscrambled data which may correspond to the direct sectors on side A. However, nothing else is unscrambled; on the original side B a lot of unscrambled text appears. This file or part of it is either compressed or scrambled.
