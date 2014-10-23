# Makefile

EXE1=d2q9-bgk.exe
EXES=$(EXE1)

#CC=gcc
#CC=tau_cc.sh
CC=icc
#CC=llc
#CFLAGS=-O3 -lm -Wall -fopenmp -ffast-math -march=native
#CFLAGS=-O3 -lm -Wall -fopenmp -ffast-math -march=native -DSINGLE_PRECISION
CFLAGS=-O3 -ipo -xHOST -no-prec-div -openmp -no-prec-sqrt -DSINGLE_PRECISION

all: $(EXES)

$(EXES): %.exe : %.c
	$(CC) $(CFLAGS) $^ -o $@ -lm

.PHONY: all clean

clean:
	\rm -f $(EXES)

eclean:
	\rm OPENMP.e*
