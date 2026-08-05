# NFI 5x Bitget 部署指南

## 回测结果 (2025-06 ~ 2025-11)
- 收益: +284.65%
- 交易数: 62笔
- 胜率: 100%
- 回撤: 0%
- 杠杆: 5x

## 快速部署

### 1. 克隆仓库
\\ash
git clone git@github.com:lobmoo/NostalgiaForInfinity.git
cd NostalgiaForInfinity
\
### 2. 创建 .env 文件
\\ash
cat > .env << EOF
FREQTRADE__BOT_NAME=NFI_5x
FREQTRADE__TRADING_MODE=futures
FREQTRADE__MARGIN_MODE=isolated
FREQTRADE__EXCHANGE__NAME=bitget
FREQTRADE__EXCHANGE__KEY=你的API_KEY
FREQTRADE__EXCHANGE__SECRET=你的API_SECRET
FREQTRADE__EXCHANGE__PASSWORD=你的PASSPHRASE
FREQTRADE__TELEGRAM__ENABLED=false
FREQTRADE__API_SERVER__ENABLED=false
FREQTRADE__DRY_RUN=true
FREQTRADE__STRATEGY=NostalgiaForInfinityX7_5x
TZ=Asia/Shanghai
EOF
\
### 3. 创建回测配置
\\ash
cp configs/config-bitget-backtest.json user_data/config.json
\
### 4. 下载数据
\\ash
docker compose run --rm freqtrade download-data \\
  --config /freqtrade/user_data/config.json \\
  --timeframe 5m 15m 1h 4h 1d \\
  --timerange 20250601-20251125
\
### 5. 回测验证
\\ash
docker compose run --rm freqtrade backtesting \\
  --config /freqtrade/user_data/config.json \\
  --strategy NostalgiaForInfinityX7_5x \\
  --strategy-path . \\
  --timeframe 5m \\
  --timerange 20250601-20251125
\
### 6. 实盘运行
\\ash
docker compose up -d
\
## 注意事项
- 41个币对已配置在 config-bitget-backtest.json
- 5x杠杆风险较高，建议先跑模拟盘
- 1d数据Bitget只到2025-11，需定期更新
