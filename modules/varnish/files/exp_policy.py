#!/usr/bin/env python3
# Show probability of caching objects according to the "exp" policy depending
# on object size. The script can be used to guesstimate how to turn the "rate"
# and "base" knobs.

import math
import argparse

parser = argparse.ArgumentParser(
    description='Show "exp" policy probabilities.'
    + 'Example: exp_policy.py --base="-20.5" --rate=0.2'
)
parser.add_argument("--memory", type=float, default=384.0)
parser.add_argument("--rate", type=float, default=0.1)
parser.add_argument("--base", type=float, default=-20.3)
args = parser.parse_args()

memory = args.memory / 1024.0

print("\nexp_policy_rate={} exp_policy_base={}\n".format(args.rate, args.base))

ADM_PARAM = (memory ** args.rate) / (2.0 ** args.base)

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
