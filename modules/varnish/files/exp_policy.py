#!/usr/bin/env python3
# Show probability of caching objects according to the "exp" policy depending
# on object size. The script can be used to guesstimate how to turn the "rate"
# and "base" knobs.

import math

MEMORY = 384.0 / 1024.0
RATE = 0.1
BASE = -20.3

ADM_PARAM = (MEMORY ** RATE) / (2.0 ** BASE)

objsize = (
    4096,
    32768,
    65536,
    131072,
    262144,
    524288,
    1048576,
    2097152,
    3145728,
    4194304,
    5242880,
    8388608,
)

for size in objsize:
    clen_neg = -1.0 * size
    prob = math.exp(clen_neg / ADM_PARAM)
    print("{: 7} KB {:.3}%".format(size / 1024, 100 * prob))
