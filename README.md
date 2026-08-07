# NostalgiaForInfinity

[![GitHub Pages](https://img.shields.io/badge/docs-online-blue)](https://iterativv.github.io/NostalgiaForInfinity/)

## 📖 Documentation

Full documentation is available online at:  
👉 [https://iterativv.github.io/NostalgiaForInfinity/](https://iterativv.github.io/NostalgiaForInfinity/)

## Introduction

Trading strategy for the [Freqtrade](https://www.freqtrade.io) crypto bot. For backtesting results, check out the comments in the individual [commit](https://github.com/iterativv/NostalgiaForInfinity/commits/main) page.

## General Recommendations

For optimal performance, suggested to use between 6 and 12 open trades, with unlimited stake.

A pairlist with 40 to 80 pairs. Volume pairlist works well.

Prefer stable coin (USDT, USDC etc) pairs, instead of BTC or ETH pairs.

Highly recommended to blacklist leveraged tokens (*BULL, *BEAR, *UP, *DOWN etc).

Ensure that you don't override any variables in you config.json. Especially the timeframe (must be 5m).

- `use_exit_signal` must set to true (or not set at all).
- `exit_profit_only` must set to false (or not set at all).
- `ignore_roi_if_entry_signal` must set to true (or not set at all).

## Automatic Updates (Docker)

The repository includes an `nfi-updater` sidecar service for Docker Compose users that keeps the strategy, blacklist, and pairlist automatically up to date without manual intervention.

**What it does:**
- Checks the strategy file, blacklist, and pairlist against the latest version on GitHub on a configurable schedule (default: every day at 10:00 AM in your timezone)
- Watches the blacklist file via HTTP ETag every 60 seconds and applies critical updates immediately
- Automatically restarts the freqtrade container only when a file actually changed

**How to enable it:**

The `nfi-updater` service is already defined in `docker-compose.yml`. It starts alongside freqtrade automatically when you run:

```bash
docker compose up -d --build
```

**Configuration (add to your `.env`):**

```env
# Timezone for the cron schedule
TZ=Europe/London

# How often to check for updates (cron syntax, default: daily at 10:00 AM)
NFI_UPDATE_CRON=0 10 * * *

# Docker Compose project name — must match what 'docker compose ls' shows
# Docker uses the lowercase folder name by default
COMPOSE_PROJECT_NAME=nostalgiaforinfinity
```

**View updater logs:**

```bash
docker compose logs -f nfi-updater
```

## Bitget Futures Deployment (5x Leverage)

### Quick Start

```bash
# 1. Clone the repository
git clone https://github.com/iterativv/NostalgiaForInfinity.git
cd NostalgiaForInfinity

# 2. Run setup script (configure proxy if needed)
chmod +x setup-bitget.sh
./setup-bitget.sh http://127.0.0.1:9001

# 3. Edit API keys
nano configs/config-bitget-dryrun.json
# Fill in: key, secret, password

# 4. Start services
docker compose -f docker-compose-bitget.yml up -d --build
```

### Manual Setup

```bash
# 1. Build custom freqtrade image
docker build -f docker/Dockerfile.custom -t freqtrade_with_numba .

# 2. Configure API keys in configs/config-bitget-dryrun.json

# 3. Start services
docker compose -f docker-compose-bitget.yml up -d --build
```

### Configuration

| Setting | Value |
|---------|-------|
| Strategy | NostalgiaForInfinityX7_5x (5x leverage) |
| Exchange | Bitget Futures (USDT-M) |
| Max Open Trades | 6 |
| Timeframe | 5m |
| Auto-Update | Daily at 10:00 AM (via nfi-updater) |

### Commands

```bash
# View trading logs
docker logs -f bitget-dryrun

# View updater logs
docker logs -f nfi-updater-bitget

# Restart bot
docker restart bitget-dryrun

# Stop all services
docker compose -f docker-compose-bitget.yml down

# Start all services
docker compose -f docker-compose-bitget.yml up -d
```

### How Auto-Update Works

The `nfi-updater` sidecar service:
1. Downloads latest `NostalgiaForInfinityX7.py` from GitHub daily
2. Creates 5x version by replacing leverage values (3.0 → 5.0)
3. Restarts the bot automatically when updates are detected
4. Also syncs blacklist and pairlist configurations

## Discord Link
This is where we chat, hangout and contribute as a community (both links is the same server)

- [Discord Invite 1](https://discord.gg/DeAmv3btxQ)
- [Discord Invite 2](https://discord.gg/nzVeNvZsQq)

## Referral Links
If you like to help, you can also use the following links to sign up to various exchanges:

- [Binance: (20% discount on trading fees)](https://www.binance.com/join?ref=C68K26A9)
- [Kucoin: (20% lifetime discount on trading fees)](https://www.kucoin.com/r/af/QBSSS5J2)
- [Gate: (20% lifetime discount on trading fees)](https://www.gate.io/share/nfinfinity)
- [OKX: (20% discount on trading fees)](https://www.okx.com/join/11749725931)
- [MEXC: (10% discount on trading fees)](https://promote.mexc.com/b/nfinfinity)
- [ByBit: (signup bonuses)](https://partner.bybit.com/b/nfi)
- [ByBit.EU: (signup bonuses)](https://partner.bybit.eu/b/NFINFINITY)
- [Bitget: (lifetime 20% rebate all plus 10% discount on spot fees)](https://bonus.bitget.com/nfinfinity)
- [Kraken: ](https://proinvite.kraken.com/9f1e/cctimhte)
- [BitMart: (20% lifetime discount on trading fees)](https://www.bitmart.com/invite/nfinfinity)
- [HTX: (Welcome Bonus worth 241 USDT upon completion of a deposit and trade)](https://www.htx.com/invite/en-us/1f?invite_code=ubpt2223)
- [ByBit: (no fees for the first € 10000)](https://bitvavo.com/invite?a=D22103A4BC)

## Donations
Absolutely not required. However, will be accepted as a token of appreciation.

- BTC: `bc1qvflsvddkmxh7eqhc4jyu5z5k6xcw3ay8jl49sk`
- ETH (ERC20): `0x83D3cFb8001BDC5d2211cBeBB8cB3461E5f7Ec91`
- BEP20/BSC (USDT, ETH, BNB, ...): `0x86A0B21a20b39d16424B7c8003E4A7e12d78ABEe`
- TRC20/TRON (USDT, TRON, ...): `TTAa9MX6zMLXNgWMhg7tkNormVHWCoq8Xk`

- Patreon : https://www.patreon.com/iterativ
