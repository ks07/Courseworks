SOURCES=$(wildcard *.v)

TARGETS=$(patsubst %.v, %.vvp, $(wildcard *_test.v))
OUTPUTS=$(patsubst %.v, %.vcd, $(wildcard *_test.v))

all : ${TARGETS}

${TARGETS} : %.vvp : ${SOURCES}
	@iverilog -Wall -s ${*} -o ${@} ${SOURCES}

clean :
	@rm -f ${TARGETS} ${OUTPUTS}
