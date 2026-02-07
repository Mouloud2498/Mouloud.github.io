#!/usr/bin/env python3
import sys
from collections import defaultdict

tot = defaultdict(float)
for line in sys.stdin:
    k, v = line.strip().split("\t")
    try:
        tot[k] += float(v)
    except:
        pass

for k in sorted(tot.keys()):
    print(f"{k}\t{tot[k]:.2f}")
