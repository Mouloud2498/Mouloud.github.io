#!/usr/bin/env python3
import sys, csv
from datetime import datetime

def parse_net(price, qty, est_retour, statut):
    price = float(price); qty = int(qty); est_retour = est_retour.strip()
    net = price * abs(qty)
    is_ret = (qty < 0) or (est_retour in ("1","true","True","YES","yes")) or (statut.lower() in ("refunded","cancelled"))
    return -net if is_ret else net

for line in sys.stdin:
    if line.strip()=="" or line.startswith("transaction_id"):
        continue
    row = next(csv.reader([line]))
    try:
        ts = row[1]; pays=row[3]; price=row[8]; qty=row[9]; est=row[15]; statut=row[18]
        month = ts[:7]  # YYYY-MM
        net = parse_net(price, qty, est, statut)
        print(f"{pays}\t{month}\t{net:.2f}")
    except Exception:
        continue
