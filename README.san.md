# Below the Root san inc ProDOS port

Quick notes on the port.

It crashes when starting any game other than the default character (Neric). In the original, this is when sectors from Side 1
are read directly with DOS RWTS.

`LOADER.SYSTEM` loads `BELOW.THE.ROOT` at $0800-$0BC5 using ProDOS MLI calls and jumps to $0800.

`BELOW.THE.RT.1` contains what may be a full image of the two BTR sides. I see a bit of unscrambled data which may correspond to the direct sectors on side A. However, nothing else is unscrambled; on the original side B a lot of unscrambled text appears. This file or part of it is either compressed or scrambled.

It's unclear if the data has been unscrambled in place, or a runtime decoder function added. The original side 1 binaries are scrambled and an unscrambler function is called at the end of DOS BLOAD (and LOAD).
