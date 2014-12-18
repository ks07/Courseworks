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

run_test() {
    SOUTFILE="sizes_out/LS${1}_RS${2}_FS${3}_OUT"
    print_test "Timing with ${@}"
    make clean
    if (( $# == 1 )); then
	make CPPFLAGS="-DLOCAL_SIZE=${1}"
    elif (( $# == 2 )); then
	make CPPFLAGS="-DLOCAL_SIZE=${1} -DREDUCTION_SIZE=${2}"
    elif (( $# == 3 )); then
	make CPPFLAGS="-DLOCAL_SIZE=${1} -DREDUCTION_SIZE=${2} -DFINAL_R_SIZE=${3}"
    fi
    $EXE "../cfgs/input_1024x1024.params" "../cfgs/obstacles_1024x1024_box.dat" "$EXTRA_ARGS" > "$SOUTFILE" 2>&1 &&
    $CHECK "../refs/av_vels_1024x1024_box.dat" "../refs/final_state_1024x1024_box.dat" "$CHECK_ARGS" >> "$SOUTFILE" 2>&1
}

mkdir sizes_out

# The preferred work group size for Blue Crystal is 32... so primarily try multiples of this
# Local sizes must divide the global space (1024^2/1024^2/40000)
for LOCAL_SIZE in 8 16 32 64 128 256; do
    for REDUCTION_SIZE in 2 4 8 16 32 64; do
	for FINAL_R_SIZE in 8 10 16 25; do
	    run_test $LOCAL_SIZE $REDUCTION_SIZE $FINAL_R_SIZE
	done
    done
done

print_test "DONE!"
