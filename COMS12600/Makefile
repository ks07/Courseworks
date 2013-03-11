SHELL 	= /bin/sh
VC	= iverilog
FLAGS	= -Wall
INT	= vvp
AASM	= ./aasm/aasm
AFLAGS	= [1000]

EMU_SRC	= emu.v
EMU_OUT	= emu.vvp

ASM_IN	= example
ASM_SRC = $(ASM_IN).s
ASM_OUT = $(ASM_IN).emu
ASM_LST	= $(ASM_IN).list

all: $(EMU_OUT)

$(EMU_OUT):
	$(VC) $(FLAGS) -o $(EMU_OUT) $(EMU_SRC)

run: $(EMU_OUT)
	$(INT) $(EMU_OUT)

compile:
	$(AASM) -l $(ASM_LST) -v $(ASM_OUT) $(AFLAGS) $(ASM_SRC)

clean:
	rm -f $(EMU_OUT) $(ASM_OUT) $(ASM_LST)