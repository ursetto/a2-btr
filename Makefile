sideA="Below the Root (4am crack) side A.dsk"
sideB="Below the Root (4am crack) side B.dsk"
files=BIGMESS DIRECT.SECTOR GAME1 GAME2 NOMORE SCREEN WINDHAM WIND
# Note: Can't decode WIND.BAS without writing unscrambled version back to floppy.

work=workA.dsk
pristine=pristineA.dsk
dos33=res/dos33.dsk

all: $(files) check $(work) $(pristine)

$(files):
	applecommander -g $(sideA) $@ > $@.scrambled
	./swizzle.py $@.scrambled $@
	rm $@.scrambled

check:
	@# on mac, brew install coreutils, then ln -s /usr/local/bin/gsha256sum ~/local/bin/sha256sum
	sha256sum -c sha256sum

init-check:
	sha256sum $(files) > sha256sum

work:
	rm -f $(work)
	make $(work)

# Create a side A work disk with some QoL enhancements.
$(work): $(files) $(dos33) WINDD2K.BAS direct_sector_2
	ln -nsf $(sideB) sideB.dsk
	cp $(dos33) $(work)
	applecommander -d $(work) HELLO
	@# Reserve T03,S00..T09,SFF (for raw sector copy)
	dd if=/dev/zero count=110 bs=256 | applecommander -p $(work) TEMP B 0x0
	applecommander -p $(work) WIND A 0x801 < WIND
	@# Upload enhanced HELLO program and strip out REMs to save space
	cat WINDD2K.BAS | sed 's/: REM.*//' | applecommander -bas $(work) HELLO
	applecommander -p $(work) NOMORE B 0x100  < NOMORE
	applecommander -p $(work) DIRECT.SECTOR B 0x300 < direct_sector_2
	applecommander -p $(work) BIGMESS B 0x330  < BIGMESS
	applecommander -p $(work) WINDHAM B 0x400  < WINDHAM
	applecommander -p $(work) GAME1 B 0xA00  < GAME1
	applecommander -p $(work) SCREEN B 0x4000 < SCREEN
	applecommander -p $(work) GAME2 B 0x6000 < GAME2
	applecommander -d $(work) TEMP

	@# Copy raw sectors T05..09,S00..0F (player char data) from original to work disk
	dd if=$(sideA) of=$(work) bs=256 skip=80 count=80 seek=80 conv=notrunc

pristine:
	rm -f $(pristine)
	make $(pristine)

# Create an unscrambled BTR Side A disk.
$(pristine): $(files) $(dos33)
	cp $(dos33) $(pristine)
	applecommander -d $(pristine) HELLO
	@# Reserve T03,S00..T09,SFF (for raw sector copy)
	dd if=/dev/zero count=110 bs=256 | applecommander -p $(pristine) TEMP B 0x0
	applecommander -p $(pristine) HELLO A 0x801 < WIND
	applecommander -p $(pristine) NOMORE B 0x100  < NOMORE
	applecommander -p $(pristine) DIRECT.SECTOR B 0x300  < DIRECT.SECTOR
	applecommander -p $(pristine) BIGMESS B 0x330  < BIGMESS
	applecommander -p $(pristine) WINDHAM B 0x400  < WINDHAM
	applecommander -p $(pristine) GAME1 B 0xA00  < GAME1
	applecommander -p $(pristine) SCREEN B 0x4000 < SCREEN
	applecommander -p $(pristine) GAME2 B 0x6000 < GAME2
	applecommander -d $(pristine) TEMP
	@# Copy raw sectors T05..09,S00..0F (player char data) from original to pristine disk
	dd if=$(sideA) of=$(pristine) bs=256 skip=80 count=80 seek=80 conv=notrunc

clean:
	rm -f $(files) $(work) $(pristine)

# Open work side A and original side B with Virtual ][ on macOS
boot: $(work)
	open workA.dsk sideB.dsk

direct_sector_2: src/direct_sector.s
	acme -o $@ -r $<.report $<

.PHONY: check init-check work-rwts work pristine boot
