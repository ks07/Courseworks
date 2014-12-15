#!/bin/bash
EXE="./d2q9-bgk.exe"
CHECK="../check_results"
EXTRA_ARGS="--device 0"

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


make oclean && make clean && make &&

# 128 box
print_test "128x128_box" &&

$EXE "../cfgs/input_128x128.params" "../cfgs/obstacles_128x128_box.dat" "$EXTRA_ARGS" &&

$CHECK "../refs/av_vels_128x128_box.dat" "../refs/final_state_128x128_box.dat" &&

# 128 square
print_test "128x128_box_square" &&

$EXE "../cfgs/input_128x128.params" "../cfgs/obstacles_128x128_box_square.dat" "$EXTRA_ARGS" &&

$CHECK "../refs/av_vels_128x128_box_square.dat" "../refs/final_state_128x128_box_square.dat" &&

# 256 sandwich
print_test "128x256_sandwich" &&

$EXE "../cfgs/input_128x256.params" "../cfgs/obstacles_128x256_sandwich.dat" "$EXTRA_ARGS" &&

$CHECK "../refs/av_vels_128x256_sandwich.dat" "../refs/final_state_128x256_sandwich.dat" &&

# 1024 (Profile this run)
print_test "1024x1024_box" &&

COMPUTE_PROFILE=1 $EXE "../cfgs/input_1024x1024.params" "../cfgs/obstacles_1024x1024_box.dat" "$EXTRA_ARGS" &&

$CHECK "../refs/av_vels_1024x1024_box.dat" "../refs/final_state_1024x1024_box.dat" &&

# 700x500
print_test "700x500_list" &&

$EXE "../cfgs/input_700x500.params" "../cfgs/obstacles_700x500_lip.dat" "$EXTRA_ARGS" &&

$CHECK "../refs/av_vels_700x500_lip.dat" "../refs/final_state_700x500_lip.dat" &&

print_test "ALL TESTS PASSED!"

if [ "$?" -ne 0 ]; then
    wc -l *.diff
fi
