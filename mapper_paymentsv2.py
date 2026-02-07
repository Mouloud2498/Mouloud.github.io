#!/usr/bin/env python3
import sys, csv

def parse_net(price, qty, est_retour, statut):
    price = float(price); qty = int(qty)
    net = price * abs(qty)
    is_ret = (qty < 0) or (est_retour in ("1","true","True","YES","yes")) or (statut.lower() in ("refunded","cancelled"))
    return -net if is_ret else net

for line in sys.stdin:
    if line.strip()=="" or line.startswith("transaction_id"):
        continue
    row = next(csv.reader([line]))
    try:
        pay = row[11]; price=row[8]; qty=row[9]; est=row[15]; statut=row[18]
        net = parse_net(price, qty, est, statut)
        print(f"{pay}\t{net:.2f}")
    except:
        continue