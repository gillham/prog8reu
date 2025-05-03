#
# Simple Makefile for a Prog8 program.
#

# Cross-platform removal command
ifeq ($(OS),Windows_NT)
    CLEAN = del /Q build\* 
    CP = copy
    RM = del /Q
    MD = mkdir
else
    CLEAN = rm -f build/*
    CP = cp -p
    RM = rm -f
    MD = mkdir -p
endif

# disk image settings
DISKTYPE=d71
DISKNAME=demoreu
DISK=build/$(DISKNAME).$(DISKTYPE)

# Emulator settings
EMU_CMD=x64sc
EMU_CMD128=x128
EMU_BASE=-default -keymap 1 -model ntsc
EMU_DISK08=-8 $(DISK) -drive8type 1571
EMU_DISK10=-fs10 build -device10 1 -iecdevice10 -virtualdev10
EMU_DISK=$(EMU_DISK08) $(EMU_DISK10)
#EMU_KERNAL=-kernal jiffykernal
#EMU_REUSIZE=2048
EMU_REUSIZE=256
#EMU_REU=-reu -reusize $(EMU_REUSIZE) -reuimage build/reu-image.bin -reuimagerw
EMU_REU=-reu -reusize $(EMU_REUSIZE)
EMU=$(EMU_CMD) $(EMU_BASE) $(EMU_KERNAL) $(EMU_DISK) $(EMU_REU)
EMU128=$(EMU_CMD128) $(EMU_BASE) $(EMU_KERNAL) $(EMU_DISK) $(EMU_REU)

PCC=prog8c
PCCARGSC64=-srcdirs src -asmlist -target c64 -out build
PCCARGSC128=-srcdirs src -asmlist -target c128 -out build

PROGS	= build/bank.lib.r build/demo64.prg build/bank.lib128.r build/demo128.prg
BANKSRC = demo/libbank.p8 demo/lib.p8 demo/bank.lib.p8
SRCS	= src/reu.p8 src/reucompat.p8
DEMOSRC = demo/demo64.p8 $(BANKSRC) $(SRCS)
DEMO128 = demo/demo128.p8 $(BANKSRC) $(SRCS)

all: build copy $(PROGS) disk

build:
	$(MD) build/

build/demo64.prg: $(DEMOSRC) $(SRCS)
	$(PCC) $(PCCARGSC64) $<

build/demo128.prg: $(DEMO128)
	$(PCC) $(PCCARGSC128) $<

build/bank.lib.r : demo/bank.lib.p8
	$(PCC) $(PCCARGSC64) $<
	$(CP) build/$(basename $(notdir $<)).bin $@

build/bank.lib128.r : demo/bank.lib.p8
	$(PCC) $(PCCARGSC128) $<
	$(CP) build/$(basename $(notdir $<)).bin $@

test: build/test.prg

build/test.prg: test/test.p8 src/reu.p8 src/reucompat.p8
	$(PCC) $(PCCARGSC64) -srcdirs src/ $<
	$(CP) test/page.bin build/
	$(CP) test/bank.bin build/
	$(CP) test/partbank.bin build/

clean:
	$(RM) build/*

copy:
	$(CP) test/load.bin build/

disk:
	c1541 -format $(DISKNAME),52 $(DISKTYPE) $(DISK) > /dev/null
	c1541 -attach $(DISK) -write build/demo64.prg demo64,p > /dev/null
	c1541 -attach $(DISK) -write build/demo128.prg demo128,p > /dev/null
	c1541 -attach $(DISK) -write build/bank.lib.r bank.lib.r,p > /dev/null
	c1541 -attach $(DISK) -write build/bank.lib128.r bank.lib128.r,p > /dev/null
	c1541 -attach $(DISK) -write test/load.bin load.bin,p > /dev/null


emu:
	$(EMU)

emu128:
	$(EMU128)

#
# end-of-file
#
