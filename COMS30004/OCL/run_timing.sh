#!/bin/bash
EXE="./d2q9-bgk.exe"
CHECK="../check_results"
EXTRA_ARGS="$MY_OCL_ARGS"
CHECK_ARGS="2"

print_test() {
    if hash figlet 2>/dev/null; then
        figlet -t "$@"
    elif hash banner 2>/dev/null; then
	banner "$@"
    else
	echo "==================="
        echo "$@"
	echo "==================="
    fi
}

SHOULD_PROFILE=0
if [ "$1" = "-profile" ]; then
    SHOULD_PROFILE=1
fi

make oclean && make clean && make &&

# Check first run, and profile if requested.
print_test "Run 0" &&

COMPUTE_PROFILE=$SHOULD_PROFILE $EXE "../cfgs/input_1024x1024.params" "../cfgs/obstacles_1024x1024_box.dat" "$EXTRA_ARGS" &&

$CHECK "../refs/av_vels_1024x1024_box.dat" "../refs/final_state_1024x1024_box.dat" "$CHECK_ARGS" &&

for i in {1..3}; do
    print_test "Run $i"
    $EXE "../cfgs/input_1024x1024.params" "../cfgs/obstacles_1024x1024_box.dat" "$EXTRA_ARGS"
done

print_test "ALL TESTS PASSED!"
