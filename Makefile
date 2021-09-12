SIDEA="Below the Root (4am crack) side A.dsk"
files=BIGMESS DIRECT.SECTOR GAME1 GAME2 NOMORE SCREEN WINDHAM
# Can't decode WIND.BAS without writing unscrambled version back to floppy.

all: $(files) check

$(files):
	applecommander -g $(SIDEA) $@ > $@.scrambled
	./swizzle.py $@.scrambled $@
	rm $@.scrambled

check:
	@# on mac, brew install coreutils, then ln -s /usr/local/bin/gsha256sum ~/local/bin/sha256sum
	sha256sum -c sha256sum

init-check:
	sha256sum $(files) > sha256sum

.PHONY: check init-check
