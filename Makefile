sideA="Below the Root (4am crack) side A.dsk"
files=BIGMESS DIRECT.SECTOR GAME1 GAME2 NOMORE SCREEN WINDHAM WIND
# Can't decode WIND.BAS without writing unscrambled version back to floppy.
work=workA.dsk
dos33=res/dos33.dsk

all: $(files) check $(work)

$(files):
	applecommander -g $(sideA) $@ > $@.scrambled
	./swizzle.py $@.scrambled $@
	rm $@.scrambled

check:
	@# on mac, brew install coreutils, then ln -s /usr/local/bin/gsha256sum ~/local/bin/sha256sum
	sha256sum -c sha256sum

init-check:
	sha256sum $(files) > sha256sum

$(work): $(files) $(dos33) WINDD2K.BAS
	cp $(dos33) $(work)
	applecommander -d $(work) HELLO
	@# Reserve T03,S00..T09,SFF (for raw sector copy)
	dd if=/dev/zero count=110 bs=256 | applecommander -p $(work) TEMP B 0x0
	applecommander -p $(work) WIND A 0x801 < WIND
	applecommander -bas $(work) HELLO < WINDD2K.BAS
	applecommander -p $(work) NOMORE B 0x100  < NOMORE
	applecommander -p $(work) DIRECT.SECTOR B 0x300  < DIRECT.SECTOR
	applecommander -p $(work) BIGMESS B 0x330  < BIGMESS
	applecommander -p $(work) WINDHAM B 0x400  < WINDHAM
	applecommander -p $(work) GAME1 B 0xA00  < GAME1
	applecommander -p $(work) SCREEN B 0x4000 < SCREEN
	applecommander -p $(work) GAME2 B 0x6000 < GAME2
	applecommander -d $(work) TEMP

	@# Copy raw sectors T05..09,S00..0F (player char data) from original to work disk
	dd if=$(sideA) of=$(work) bs=256 skip=80 count=80 seek=80 conv=notrunc

.PHONY: check init-check work-rwts work
