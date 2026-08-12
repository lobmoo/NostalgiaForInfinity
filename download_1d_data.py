#!/usr/bin/env python3
"""Download 1d data from Bitget API in chunks to bypass the 90-candle limit."""

import json
import time
import requests
import pyarrow as pa
import pyarrow.feather as feather
import pandas as pd
from datetime import datetime, timezone
import os
import sys

PROXY = os.environ.get("PROXY_URL", os.environ.get("HTTP_PROXY", "http://127.0.0.1:9001"))
BASE_URL = "https://api.bitget.com/api/v2/mix/market/candles"
DATA_DIR = "user_data/data/bitget/futures"
PRODUCT_TYPE = "USDT-FUTURES"
GRANULARITY = "1Dutc"
LIMIT = 100

# Load pairs from config
with open("configs/config-bitget-backtest.json") as f:
    config = json.load(f)
pairs = config["exchange"]["pair_whitelist"]

# Time range: 2025-01-01 to 2026-08-07
START_TS = int(datetime(2025, 1, 1, tzinfo=timezone.utc).timestamp() * 1000)
END_TS = int(datetime(2026, 8, 7, tzinfo=timezone.utc).timestamp() * 1000)

CHUNK_DAYS = 85  # Stay under 90-day limit

def fetch_candles(symbol, start_ts, end_ts):
    """Fetch candles from Bitget API with pagination in 85-day chunks."""
    all_candles = []
    current_start = start_ts
    chunk_ms = CHUNK_DAYS * 86400000  # 85 days in ms

    while current_start < end_ts:
        chunk_end = min(current_start + chunk_ms, end_ts)

        params = {
            "symbol": symbol,
            "granularity": GRANULARITY,
            "startTime": str(current_start),
            "endTime": str(chunk_end),
            "limit": str(LIMIT),
            "productType": PRODUCT_TYPE,
        }

        try:
            resp = requests.get(BASE_URL, params=params, proxies={"https": PROXY, "http": PROXY}, timeout=30)
            data = resp.json()

            if data.get("code") != "00000":
                print(f"  API error: {data.get('msg', 'unknown')}")
                current_start = chunk_end
                continue

            candles = data.get("data", [])
            if candles:
                all_candles.extend(candles)

            time.sleep(0.15)  # Rate limit

        except Exception as e:
            print(f"  Error: {e}")

        current_start = chunk_end

    return all_candles

def save_feather(candles, filepath):
    """Save candles to feather format."""
    if not candles:
        return 0

    rows = []
    for c in candles:
        rows.append({
            "date": int(c[0]),
            "open": float(c[1]),
            "high": float(c[2]),
            "low": float(c[3]),
            "close": float(c[4]),
            "volume": float(c[5]),
        })

    df = pd.DataFrame(rows)
    df["date"] = pd.to_datetime(df["date"], unit="ms", utc=True)

    table = pa.Table.from_pandas(df)
    feather.write_feather(table, filepath)

    return len(rows)

print(f"Downloading 1d data for {len(pairs)} pairs...")
print(f"Time range: {datetime.fromtimestamp(START_TS/1000, tz=timezone.utc)} to {datetime.fromtimestamp(END_TS/1000, tz=timezone.utc)}")
print()

for pair in pairs:
    # Convert pair to symbol format: BTC/USDT:USDT -> BTCUSDT
    symbol = pair.split("/")[0] + pair.split("/")[1].split(":")[0]

    # File path: BTC_USDT_USDT-1d-futures.feather
    pair_file = pair.replace("/", "_").replace(":", "_") + "-1d-futures.feather"
    filepath = os.path.join(DATA_DIR, pair_file)

    print(f"Downloading {pair} ({symbol})...", end=" ", flush=True)

    candles = fetch_candles(symbol, START_TS, END_TS)

    if candles:
        count = save_feather(candles, filepath)
        print(f"{count} candles saved")
    else:
        print("No data")

print("\nDone!")
