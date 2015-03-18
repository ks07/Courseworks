#!/usr/bin/env python2
from __future__ import print_function
import math

# Stuck between a rock and a hard place
# Frying pan and the fire
# Porting Python to C and C to Python
# ...we choose the latter

def find_omega(N):
    w = 64
    omega = 1
    # TODO: Bad
    N_lsl = mpz_getlimbn(N, 0)

    for i in range(1, w):
        # TODO: Bad
        omega = mpz_getlimbn(omega * omega, 0)
        omega = mpz_getlimbn(omega * N_lsl, 0)

    omega = (2 ** 64) - omega
    return omega

def find_rhosq(N):
    rho_sq = 1
    lim = 2 * mpz_size(N) * 64
    
    for i in xrange(0, lim):
        rho_sq = rho_sq * 2
        if rho_sq >= N:
            rho_sq = rho_sq - N

    return rho_sq

def get_mp(N):
    mp = {}
    mp['N'] = N
    mp['omega'] = find_omega(N)
    mp['rho_sq'] = find_rhosq(N)
    return mp

def mpz_size(N):
    return int(math.ceil(math.log(N, 2**64)))

def mpz_getlimbn(x, n):
    limb_bits = 64
    limb_mask = (2 ** limb_bits) - 1
    limb_offset = n * limb_bits
    limb = (x >> limb_offset) & limb_mask
    return limb

def mont_mul(x, y, mp):
    u = 0
    lN = mpz_size(mp['N'])
    r = 0L

    for i in range(0, lN):
        print("QQ")
        

if __name__ == "__main__":
    # Run some simple tests with some fixed values taken from our C implementation
    N = 67904591690960625685176102005990337496786740709623937212838922679922983036690323147526875231447485364833208798244563167265927305187713466112908513868402652001032936944256370570913518925501241679737467579383754432622376609693387551255713799338068557786526125073913330768378515485771456109044135994550676411187L

    assert mpz_size(N) == 16
    assert mpz_getlimbn(N, 2) == 13853186540086312366

    assert find_omega(N) == 12132467263235727365
    assert find_rhosq(N) == 24733578175677155822271607372585377657694123229601842059113029975719763419416548152342124685480818235906131633966260259692677567940685556540213815522472406678846708899779654571603309102177008106044883884903579150907160820914715207554124279680009896558548886800517477463703900084974729045866390906269371193572
    print("OK!")
