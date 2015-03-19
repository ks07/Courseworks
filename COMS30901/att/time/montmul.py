#!/usr/bin/env python2
from __future__ import print_function
import math, random

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
    limb_bits = 64 # TODO: Constant-ify
    limb_mask = (2 ** limb_bits) - 1
    limb_offset = n * limb_bits
    limb = (x >> limb_offset) & limb_mask
    return limb

def mpz_tdiv_q_2exp(r, b):
    return r >> b

def mont_mul(x, y, mp):
    red = False
    lN = mpz_size(mp['N'])
    r = 0L

    assert lN > 0
    assert mp['omega'] < (2**64)
    assert mp['rho_sq'] < mp['N']

    for i in range(0, lN):
        u = mpz_getlimbn(x, 0) * mpz_getlimbn(y, i)
        u = mpz_getlimbn(u, 0)
        u = u + mpz_getlimbn(r, 0)
        u = mpz_getlimbn(u, 0)
        u = u * mp['omega']
        u = mpz_getlimbn(u, 0)

        assert u < 2**64
        assert u == ((mpz_getlimbn(r, 0) + mpz_getlimbn(x, 0) * mpz_getlimbn(y, i)) * mp['omega']) % (2**64)
        
        r = r + x * mpz_getlimbn(y, i) + mp['N'] * u
        r = mpz_tdiv_q_2exp(r, 64) #TODO: constant
        
    if r >= mp['N']:
        red = True
        r = r - mp['N']

    assert r < mp['N']
    return (r, red)

def get_mont_rep(x, mp):
    return mont_mul(x, mp['rho_sq'], mp)[0]

def undo_mont_rep(r_m, mp):
    return mont_mul(r_m, 1, mp)[0]

# if __name__ == "__main__":
#     # Run some simple tests with some fixed values taken from our C implementation
#     N = 67904591690960625685176102005990337496786740709623937212838922679922983036690323147526875231447485364833208798244563167265927305187713466112908513868402652001032936944256370570913518925501241679737467579383754432622376609693387551255713799338068557786526125073913330768378515485771456109044135994550676411187L

#     assert mpz_size(N) == 16
#     assert mpz_getlimbn(N, 2) == 13853186540086312366

#     assert find_omega(N) == 12132467263235727365
#     assert find_rhosq(N) == 24733578175677155822271607372585377657694123229601842059113029975719763419416548152342124685480818235906131633966260259692677567940685556540213815522472406678846708899779654571603309102177008106044883884903579150907160820914715207554124279680009896558548886800517477463703900084974729045866390906269371193572L

#     mp = get_mp(N)

#     x = random.randrange(N)
#     x_m = get_mont_rep(x, mp)
#     assert(undo_mont_rep(x_m, mp) == x)

#     for i in range(0, 100):
#         x = random.randrange(N)
#         y = random.randrange(N)
#         x_m = get_mont_rep(x, mp)
#         y_m = get_mont_rep(y, mp)
#         r_m, red = mont_mul(x_m, y_m, mp)
#         r = (x * y) % N
#         assert(r == undo_mont_rep(r_m, mp))

#     print("OK!")
