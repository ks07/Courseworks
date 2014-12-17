# Makefile

EXE1=d2q9-bgk.exe
EXES=$(EXE1)

#CC=mpicc
#CC=mpiicc
#CFLAGS=-O3 -lm -Wall -ffast-math -march=native -DSINGLE_PRECISION -std=c99
#CFLAGS=-O3 -lm -Wall -march=native -std=c99 -g
#CFLAGS=-O3 -ipo -xHOST -no-prec-div -no-prec-sqrt -DSINGLE_PRECISION -std=c99
CXX=g++

CPP_COMMON=./Cpp_common

INC=-I $(CPP_COMMON) -I /usr/local/cuda/include/

LIBS=-L /usr/local/cuda/lib64/ -lm -lOpenCL -lrt

ifndef DEVICE
	DEVICE = CL_DEVICE_TYPE_DEFAULT
endif

CXXFLAGS=-O3 -ffast-math -Wall -march=native -DSINGLE_PRECISION -DDEVICE=$(DEVICE)

all: $(EXES)

$(EXES): %.exe : %.cpp
	$(CXX) $^ $(INC) $(CXXFLAGS) $(LIBS) -o $@

.PHONY: all clean

clean:
	\rm -f $(EXES)

oclean:
	\rm -f OpenCL*.e*
	\rm -f machine.file.*
	\rm -f OUT
	\rm -f av_vels.dat
	\rm -f final_state.dat
	\rm -f opencl_profile_0.*
