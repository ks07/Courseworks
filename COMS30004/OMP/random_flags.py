#!/usr/bin/env python2

import subprocess, os, random

TO_GENERATE=50

CC="gcc"

SRC_FILE=" d2q9-bgk.c "

OUTPUT_FLAG=" -o d2q9-bgk.exe"

FLAGS_ALWAYS=" -lm -fopenmp -DSINGLE_PRECISION -march=native "

# Command to run to get flag list! May need manual pruning for target/language compatibility.
# gcc -c -Q -O3 --help=optimizers | grep '\-f' | grep '\[' | awk '{print $1}' | sed -e 's/$/\",/' | sed -e 's/^/\"/'

#Some of these may overlap with always flags, should not matter.
FLAGS_OPTIONAL=[
"-faggressive-loop-optimizations",
"-falign-functions",
"-falign-jumps",
"-falign-labels",
"-falign-loops",
"-fasynchronous-unwind-tables",
"-fbranch-count-reg",
"-fbranch-probabilities",
"-fbranch-target-load-optimize",
"-fbranch-target-load-optimize2",
"-fbtr-bb-exclusive",
"-fcaller-saves",
"-fcombine-stack-adjustments",
"-fcommon",
"-fcompare-elim",
"-fconserve-stack",
"-fcprop-registers",
"-fcrossjumping",
"-fcse-follow-jumps",
"-fcx-fortran-rules",
"-fcx-limited-range",
"-fdata-sections",
"-fdce",
"-fdefer-pop",
"-fdelete-null-pointer-checks",
"-fdevirtualize",
"-fdse",
"-fearly-inlining",
"-fexceptions",
"-fexpensive-optimizations",
"-ffinite-math-only",
"-ffloat-store",
"-fforward-propagate",
"-fgcse",
"-fgcse-after-reload",
"-fgcse-las",
"-fgcse-lm",
"-fgcse-sm",
"-fguess-branch-probability",
"-fhoist-adjacent-loads",
"-fif-conversion",
"-fif-conversion2",
"-finline",
"-finline-atomics",
"-finline-functions",
"-finline-functions-called-once",
"-finline-small-functions",
"-fipa-cp",
"-fipa-cp-clone",
"-fipa-profile",
"-fipa-pta",
"-fipa-pure-const",
"-fipa-reference",
"-fipa-sra",
"-fira-hoist-pressure",
"-fivopts",
"-fjump-tables",
"-floop-nest-optimize",
"-fmath-errno",
"-fmerge-all-constants",
"-fmerge-constants",
"-fmodulo-sched",
"-fmove-loop-invariants",
"-fnon-call-exceptions",
"-fomit-frame-pointer",
"-fopt-info",
"-foptimize-register-move",
"-foptimize-sibling-calls",
"-foptimize-strlen",
"-fpack-struct",
"-fpeel-loops",
"-fpeephole",
"-fpeephole2",
"-fpredictive-commoning",
"-fprefetch-loop-arrays",
"-freg-struct-return",
"-fregmove",
"-frename-registers",
"-freorder-blocks",
"-freorder-blocks-and-partition",
"-freorder-functions",
"-frerun-cse-after-loop",
"-freschedule-modulo-scheduled-loops",
"-frounding-math",
"-fsched-critical-path-heuristic",
"-fsched-dep-count-heuristic",
"-fsched-group-heuristic",
"-fsched-interblock",
"-fsched-last-insn-heuristic",
"-fsched-pressure",
"-fsched-rank-heuristic",
"-fsched-spec",
"-fsched-spec-insn-heuristic",
"-fsched-spec-load",
"-fsched-spec-load-dangerous",
"-fsched-stalled-insns",
"-fsched-stalled-insns-dep",
"-fsched2-use-superblocks",
"-fschedule-insns",
"-fschedule-insns2",
"-fsel-sched-pipelining",
"-fsel-sched-pipelining-outer-loops",
"-fsel-sched-reschedule-pipelined",
"-fselective-scheduling",
"-fselective-scheduling2",
"-fshort-double",
"-fshort-enums",
"-fshort-wchar",
"-fshrink-wrap",
"-fsignaling-nans",
"-fsigned-zeros",
"-fsingle-precision-constant",
"-fsplit-ivs-in-unroller",
"-fsplit-wide-types",
"-fstrict-aliasing",
"-fthread-jumps",
"-ftoplevel-reorder",
"-ftrapping-math",
"-ftrapv",
"-ftree-bit-ccp",
"-ftree-builtin-call-dce",
"-ftree-ccp",
"-ftree-ch",
"-ftree-coalesce-inlined-vars",
"-ftree-coalesce-vars",
"-ftree-copy-prop",
"-ftree-copyrename",
"-ftree-cselim",
"-ftree-dce",
"-ftree-dominator-opts",
"-ftree-dse",
"-ftree-forwprop",
"-ftree-fre",
"-ftree-loop-distribute-patterns",
"-ftree-loop-distribution",
"-ftree-loop-if-convert",
"-ftree-loop-if-convert-stores",
"-ftree-loop-im",
"-ftree-loop-ivcanon",
"-ftree-loop-optimize",
"-ftree-lrs",
"-ftree-partial-pre",
"-ftree-phiprop",
"-ftree-pre",
"-ftree-pta",
"-ftree-reassoc",
"-ftree-scev-cprop",
"-ftree-sink",
"-ftree-slp-vectorize",
"-ftree-slsr",
"-ftree-sra",
"-ftree-switch-conversion",
"-ftree-tail-merge",
"-ftree-ter",
"-ftree-vect-loop-version",
"-ftree-vectorize",
"-ftree-vrp",
"-funit-at-a-time",
"-funroll-all-loops",
"-funroll-loops",
"-funsafe-loop-optimizations",
"-funsafe-math-optimizations",
"-funswitch-loops",
"-funwind-tables",
"-fvariable-expansion-in-unroller",
"-fvect-cost-model",
"-fvpt",
"-fweb",
"-fwhole-program",
"-fwrapv"
]

def create_cmdline():
    cmdline = CC + FLAGS_ALWAYS
    
    # We want to collect a random sample of flags from the list of optionals.
    # Need to provide a random k, as there may be a benefit to having fewer or greater flags.
    sample_size = random.randint(0, len(FLAGS_OPTIONAL) - 1)
    our_flags = random.sample(FLAGS_OPTIONAL, sample_size)

    for flag in our_flags:
        cmdline += flag + " "

    # Append the source file and output argument
    cmdline += SRC_FILE + OUTPUT_FLAG

    return cmdline

if __name__ == '__main__':
    for i in xrange(TO_GENERATE):
        print 'START COMPILATION NUMBER:', i
        cmdline = create_cmdline()
        print cmdline

        os.system(cmdline + " && ./d2q9-bgk.exe cfgs/input_128x128.params cfgs/obstacles_128x128_box.dat && ./check_results refs/av_vels_128x128_box.dat refs/final_state_128x128_box.dat")
