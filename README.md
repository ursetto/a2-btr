# Below the Root analysis project for Apple II

This repository contains:

- SourceGen disassembly of Below the Root for the Apple II
- [Documentation](https://ursetto.github.io/a2-btr) with a discussion of the program and its analysis
- [Disassembly](https://ursetto.github.io/a2-btr/#disassembly) output 

## Disassembly details

Disassembly is not yet complete, but large portions are done. I did the disassembly using [6502bench SourceGen](https://6502bench.com) with each source file (module) as a separate project. The files are exported to HTML in [docs/](./docs/), in common assembler syntax with widths of 22/8/24/100 (label/opcode/operand/comment), plus long labels on separate lines. At the moment, it is not exported to actual source files. The docs are made available as [GitHub Pages](https://ursetto.github.io/a2-btr).

The style is a little inconsistent, but generally zero-page variables look `likeThis` or occasionally `LIKETHIS`, and code labels look `like_this`. Structure members or constants are usually named like `STRUCT_member`.

Shared code and data between modules needs to be marked with exported global labels, and manually imported into any project any time they change with `Edit > Project Properties > Project Symbols`. This is an unfortunate limitation of SourceGen, but it's otherwise so great that I can't complain. Nearly all cross-module jumps are to well-known external vectors, presumably to avoid having to relink every module when code got moved around.

Zero-page values are in [BTR-zp.sym65](./BTR-zp.sym65) and imported just once into each project in `Edit` > `Project Properties` > `Symbol Files`.

- When I find a variable I don't understand, for example `$8d`, I add it and name it like `zp8d`. This allows the cross-referencing function of the analyzer to work -- it won't cross-reference unnamed locations.
- Zero-page vars I am uncertain about may have a proposed name added, like `zp6b_npcHere`, until I can confirm it and rename it `npcHere`.
- Temporary variables are named like `temp81` for $81. Sometimes I use the "local variable" feature of SourceGen, to name the temp in a subroutine for clarity. I clear the table afterward so it doesn't leak out, and still register it as `tempXX` in the symbol file, because this lets you see if it's used elsewhere.
- There are quite a few "unique" temporaries that are only ever used in one place, and could have been reused. I name these as normal temps and usually make a note of that in the comment.

Non-zero-page data references that are not in a module are in [BTR.sym65](./BTR.sym65). For example, game state in $B200-$B5FF, and the RWTS buffer values at $0200. In retrospect, there is not a particularly good reason to have 2 separate symbol files.

I wrote a custom SourceGen module, [InlineBTRString.cs](./InlineBTRString.cs), to parse the unique inline string format used in BTR. Basically, it looks for JSRs to the string printing function and transforms the code and data around that. Without this, the analyzer had a very hard time differentiating code from data.

## Makefile

Obtain `Below the Root (4am crack) side A.dsk` and `Below the Root (4am crack) side B.dsk` and copy them into this directory. [applecommander](https://github.com/AppleCommander/AppleCommander) is required.

After typing `make`, you will have:

- cleartext (unswizzled) copies of the files on side A
- a bootable, unscrambled side A disk `pristineA.dsk`
- a bootable side A disk `workA.dsk` with minor enhancements
- `sideB.dsk`, a symlink to the BTR Side B disk for convenience.

Enhancements:

- Enables 2 drives. Place `workA.dsk` in drive 1 and side B in drive 2. Useful for accelerated boot and test.
- Selects keyboard mode automatically, implicitly skipping the prompt to insert side 2.

Issues:

- Must choose Neric to avoid disk swapping. Otherwise, you must swap side A into drive 2 (!) for a moment when starting a new game.
- Must insert storage disk into drive 2, if saving/loading.

The new game swap issue can be fixed with a small change to `read_char_data` ($AE1D) to temporarily set the default drive to 1 and skip the disk prompts.

