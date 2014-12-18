# Makefile

EXE1=d2q9-bgk.exe
EXES=$(EXE1)

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
	$(CXX) $^ $(INC) $(CPPFLAGS) $(CXXFLAGS) $(LIBS) -o $@

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
	\rm -f av_vels.diff
	\rm -f final_state.diff
