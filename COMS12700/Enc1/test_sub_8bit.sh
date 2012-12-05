#!/bin/bash

make sub_8bit_test.vvp &&
make equ_8bit_test.vvp &&

testsub () {
for OP in 0 1
do
    for X in `eval echo {$1..$2}`
    do
	for Y in `eval echo {$3..$4}`
	do
	    for CI in 0 1
	    do
		CMD="vvp sub_8bit_test.vvp -none +x=$X +y=$Y +op=$OP +ci=$CI"

		OUTPUT=$($CMD)

		FILTER="echo '$OUTPUT' | egrep -o 'r=[0-9xz]+' | cut -d '=' -f 2"
		R=$(eval $FILTER)

		OF_FILTER="echo '$OUTPUT' | egrep -o 'of=[01]' | cut -d '=' -f 2"
		OF=$(eval $OF_FILTER)

		if (( OP == 0 ))
		then
		    RE=$((X + Y + CI))
		else
		    RE=$((X - Y - CI))
		fi

		if (( RE > 127 )) || (( RE < -128 ))
		then
		    OFE=1
		else
		    OFE=0
		fi

		if (( R != RE )) && (( OFE != OF ))
		then
		    echo "Mismatch! X:$X Y:$Y CI:$CI OP:$OP R:$R RE:$RE OF:$OF OFE:$OFE"
		    sleep 10 s
		fi
	    done
	done
    done
done


echo "Completed testsub for X: $1 - $2 Y: $1 - $2"
}

testequ () {
for X in `eval echo {$1..$2}`
do
    for Y in `eval echo {$3..$4}`
    do
	CMD="vvp equ_8bit_test.vvp -none +x=$X +y=$Y"
	OUTPUT=$($CMD)
	FILTER="echo '$OUTPUT' | egrep -o 'r=[01xz]' | cut -d '=' -f 2"
	R=$(eval $FILTER)
	
	if (( X == Y ))
	then
	    RE=1
	else
	    RE=0
	fi
	
	if (( R != RE )) && (( OFE != OF ))
	then
	    echo "Mismatch! X:$X Y:$Y R:$R RE:$RE"
	    sleep 10 s
	fi
    done
done

echo "Completed testequ for X: $1 - $2 Y: $1 - $2"
}

testsub -128 -65 -128 -1 &
testsub -64 -1 -128 -1 &
testsub 0 64 -128 -1 &
testsub 65 127 -128 -1 &
testsub -128 -65 0 127 &
testsub -64 -1 0 127 &
testsub 0 64 0 127 &
testsub 65 127 0 127 &

testequ -128 -1 -128 -1 &
testequ -128 -1 0 127 &
testequ 0 127 -128 -1 &
testequ 0 127 0 127 &

wait