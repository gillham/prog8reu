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

# Emulator settings
EMU_CMD=x64sc
EMU_BASE=-default -keymap 1 -model ntsc
EMU_DISK=-fs8 build -device8 1 -iecdevice8 -virtualdev8
#EMU_KERNAL=-kernal jiffykernal
EMU_REUSIZE=2048
EMU_REU=-reu -reusize $(EMU_REUSIZE) -reuimage bin/reu-image.bin -reuimagerw
EMU=$(EMU_CMD) $(EMU_BASE) $(EMU_KERNAL) $(EMU_DISK) $(EMU_REU)

PCC=prog8c
PCCARGSC64=-srcdirs src -asmlist -target c64 -out build

PROGS	= build/bank.lib.r build/main.prg
DEMOSRC = demo/main.p8 demo/libbank.p8 demo/lib.p8 demo/bank.lib.p8
SRCS	= src/reu.p8 src/reucompat.p8

all: build copy $(PROGS)

build:
	$(MD) build/

build/main.prg: $(DEMOSRC) $(SRCS)
	$(PCC) $(PCCARGSC64) $<

build/%.r : demo/%.p8
	$(PCC) $(PCCARGSC64) $<
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

emu:
	$(EMU)

#
# end-of-file
#
