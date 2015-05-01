#!/usr/bin/env python3
import sys, math, random

LCP_count = 0

def LCP(T, P, i, j):
    global LCP_count
    LCP_count += 1
    L = 1

    limit = len(P) - j

    for pos in range(0, limit):
        if T[i+pos] == P[j+pos]:
            L += 1
        else:
            break
    return L

def inner_body(k, T, P):
    TC = 0.0
    i = 0
    j = 0
    L = LCP(T, P, i, j)

    n = len(T)
    m = len(P)

    if L < m:
        TC = 1.0
        i = L
        j = L
        while TC <= k:
            L = LCP(T,P,i,j)
            i += L
            j += L
            if j > m or i > n:
                break;
            else:
                TC += (float(m)/L)
    return TC if TC <= k else 'X'

def mutate_bin(x):
    x_i = int(x, 2)
    # Add up to 20 errors
    for i in range(random.randrange(20)):
        max_pos = len(x) - 1
        error_bit = pow(2, random.randrange(0,max_pos+1))
        # Do the error
        x_i = x_i ^ error_bit
    return (bin(x_i)[2:]).zfill(len(x))

#text = '01234567'
#patt = 'X12X456X'
text = '00000000'
patt = '10101011'
k = 20

if __name__ == '__main__':
    if (len(sys.argv) == 4):
        text = sys.argv[1]
        patt = sys.argv[2]
        k = int(sys.argv[3])
        TC = inner_body(k, text, patt)
        print(LCP_count, math.sqrt(k), TC)
    else:
        for i in range(200):
            LCP_count = 0
            m = random.randrange(100,1000)
            text = bin(random.getrandbits(m))[2:]
            #patt = bin(random.getrandbits(m))[2:]
            patt = mutate_bin(text)
            text = text.zfill(len(patt)) # Ensure the text is at least patt sized
            k = random.randrange(1, pow(len(patt), 2))
            TC = inner_body(k, text, patt)
            supposed_bound = int(math.sqrt(k)) + 1
            #print(text)
            #print(patt)
            if LCP_count >= supposed_bound:
                print('Uhoh', text, patt, k, TC, LCP_count, supposed_bound)
