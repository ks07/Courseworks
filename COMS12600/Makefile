SHELL 	= /bin/sh
VC	= iverilog
FLAGS	= -Wall
INT	= vvp

EMU_SRC	= emu.v
EMU_OUT	= emu.vvp

all: $(EMU_OUT)

$(EMU_OUT):
	$(VC) $(FLAGS) -o $(EMU_OUT) $(EMU_SRC)

run: $(EMU_OUT)
	$(INT) $(EMU_OUT)
