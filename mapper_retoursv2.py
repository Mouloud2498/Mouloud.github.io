#!/usr/bin/env python3
import sys, csv

for line in sys.stdin:
    if line.strip()=="" or line.startswith("transaction_id"):
        continue
    row = next(csv.reader([line]))
    try:
        qty = int(row[9]); est=row[15]; statut=row[18].lower()
        is_ret = (qty < 0) or (est in ("1","true","True","YES","yes")) or (statut in ("refunded","cancelled"))
        print(f"T\t1")
        print(f"R\t{1 if is_ret else 0}")
    except:
        continue