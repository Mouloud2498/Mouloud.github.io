#!/usr/bin/env python3
import sys, heapq

from collections import defaultdict
tot = defaultdict(float)
for line in sys.stdin:
    try:
        k, v = line.strip().split("\t")
        tot[k] += float(v)
    except:
        pass

# top 10 par valeur décroissante
top = heapq.nlargest(10, tot.items(), key=lambda kv: kv[1])
for prod, val in top:
    print(f"{prod}\t{val:.2f}")