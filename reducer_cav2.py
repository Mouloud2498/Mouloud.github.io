#!/usr/bin/env python3
import sys
from collections import defaultdict

agg = defaultdict(float)
for line in sys.stdin:
    parts = line.strip().split("\t")
    if len(parts)!=3: 
        continue
    pays, month, val = parts
    try:
        agg[(pays, month)] += float(val)
    except:
        pass

# tri par pays puis mois
for (p, m) in sorted(agg.keys()):
    print(f"{p}\t{m}\t{agg[(p,m)]:.2f}")
