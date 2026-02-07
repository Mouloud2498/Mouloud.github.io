#!/usr/bin/env python3
import sys

total = 0
ret = 0
for line in sys.stdin:
    k, v = line.strip().split("\t")
    v = int(v)
    if k=="T":
        total += v
    elif k=="R":
        ret += v

rate = (ret/total)*100 if total>0 else 0.0
print(f"total_transactions\t{total}")
print(f"retours\t{ret}")
print(f"taux_retour_%\t{rate:.2f}")