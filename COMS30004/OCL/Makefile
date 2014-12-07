# Makefile

EXE1=d2q9-bgk.exe
EXES=$(EXE1)

#CC=mpicc
#CC=mpiicc
#CFLAGS=-O3 -lm -Wall -ffast-math -march=native -DSINGLE_PRECISION -std=c99
#CFLAGS=-O3 -lm -Wall -march=native -std=c99 -g
#CFLAGS=-O3 -ipo -xHOST -no-prec-div -no-prec-sqrt -DSINGLE_PRECISION -std=c99
CXX=g++
CXXFLAGS=-O3 -lm -Wall -march=native -DSINGLE_PRECISION -L /usr/local/cuda/lib64/ -lOpenCL -lrt

all: $(EXES)

$(EXES): %.exe : %.cpp
	$(CXX) $(CXXFLAGS) $^ -o $@ -lm

.PHONY: all clean

clean:
	\rm -f $(EXES)

oclean:
	\rm -f MPI.e*
	\rm -f machine.file.*
	\rm -f OUT
	\rm -f av_vels.dat
	\rm -f final_state.dat
