#!/bin/bash
# ============================================
# Bitget 模拟盘一键部署脚本
# 用法: ./deploy-bitget-demo.sh
# ============================================

set -e

# ============ 用户配置区 - 只改这里 ============

# Bitget 模拟盘 API Key (在 demo.bitget.com 创建)
BITGET_API_KEY=""
BITGET_API_SECRET=""
BITGET_API_PASSPHRASE=""

# Telegram 通知 (在 @BotFather 创建 Bot)
TELEGRAM_BOT_TOKEN=""
TELEGRAM_CHAT_ID=""

# 代理地址 (没有代理留空)
PROXY_URL=""

# ============ 配置结束 ============

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "=========================================="
echo " Bitget 模拟盘部署脚本"
echo " NostalgiaForInfinityX7_5x (5x杠杆)"
echo "=========================================="
echo ""

# 检查配置
if [ -z "$BITGET_API_KEY" ]; then
    echo -e "${RED}错误: 请先填写 BITGET_API_KEY${NC}"
    echo "编辑此脚本，填写 Bitget 模拟盘 API Key"
    exit 1
fi

if [ -z "$BITGET_API_SECRET" ]; then
    echo -e "${RED}错误: 请先填写 BITGET_API_SECRET${NC}"
    exit 1
fi

if [ -z "$BITGET_API_PASSPHRASE" ]; then
    echo -e "${RED}错误: 请先填写 BITGET_API_PASSPHRASE${NC}"
    exit 1
fi

# 检查 Docker
if ! command -v docker &> /dev/null; then
    echo -e "${RED}错误: 未安装 Docker${NC}"
    exit 1
fi

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo -e "${GREEN}[1/6] 构建 Docker 镜像...${NC}"
if ! docker image inspect freqtrade_with_numba &>/dev/null; then
    echo "freqtrade_with_numba 镜像不存在，开始构建..."
    docker build -t freqtrade_with_numba -f docker/Dockerfile.custom .
    echo "镜像构建完成"
else
    echo "freqtrade_with_numba 镜像已存在，跳过构建"
fi

echo -e "${GREEN}[2/6] 创建配置文件...${NC}"

# 创建 user_data 目录
mkdir -p user_data/data user_data/logs user_data/backtest_results

# 生成代理配置
PROXY_CONFIG=""
ASYNC_PROXY_CONFIG=""
if [ -n "$PROXY_URL" ]; then
    PROXY_CONFIG="\"httpsProxy\": \"$PROXY_URL\","
    ASYNC_PROXY_CONFIG="\"httpsProxy\": \"$PROXY_URL\","
fi

# 生成 Telegram 配置
TELEGRAM_CONFIG=""
if [ -n "$TELEGRAM_BOT_TOKEN" ] && [ -n "$TELEGRAM_CHAT_ID" ]; then
    TELEGRAM_CONFIG="\"telegram\": {
    \"enabled\": true,
    \"token\": \"$TELEGRAM_BOT_TOKEN\",
    \"chat_id\": \"$TELEGRAM_CHAT_ID\",
    \"notification_settings\": {
      \"entry_fill\": \"on\",
      \"exit_fill\": \"on\",
      \"protection_trigger\": \"on\",
      \"protection_trigger_global\": \"on\"
    }
  },"
else
    TELEGRAM_CONFIG="\"telegram\": {\"enabled\": false},"
fi

# 生成配置文件
cat > configs/config-bitget-live.json << EOFCONFIG
{
  "strategy": "NostalgiaForInfinityX7_5x",
  "trading_mode": "futures",
  "margin_mode": "isolated",
  "max_open_trades": 6,
  "stake_currency": "USDT",
  "stake_amount": "unlimited",
  "tradable_balance_ratio": 0.99,
  "dry_run": false,
  "cancel_open_orders_on_exit": false,
  "timeframe": "5m",
  "exchange": {
    "name": "bitget",
    "key": "$BITGET_API_KEY",
    "secret": "$BITGET_API_SECRET",
    "password": "$BITGET_API_PASSPHRASE",
    "ccxt_config": {
      "options": {
        "defaultType": "swap"
      },
      $PROXY_CONFIG
      "rateLimit": 50,
      "timeout": 30000,
      "retries": 5,
      "headers": {
        "paptrading": "1"
      }
    },
    "ccxt_async_config": {
      "options": {
        "defaultType": "swap"
      },
      "enableRateLimit": true,
      "rateLimit": 60,
      $ASYNC_PROXY_CONFIG
      "timeout": 30000,
      "retries": 5,
      "headers": {
        "paptrading": "1"
      }
    }
  },
  "pairlists": [
    {
      "method": "VolumePairList",
      "number_assets": 70,
      "sort_key": "quoteVolume",
      "refresh_period": 1800
    },
    { "method": "AgeFilter", "min_days_listed": 60 },
    {
      "method": "PriceFilter",
      "low_price_ratio": 0.003
    },
    {
      "method": "SpreadFilter",
      "max_spread_ratio": 0.008
    }
  ],
  "entry_pricing": {
    "price_side": "other",
    "use_order_book": true,
    "order_book_top": 1
  },
  "exit_pricing": {
    "price_side": "other",
    "use_order_book": true,
    "order_book_top": 1
  },
  $TELEGRAM_CONFIG
  "bot_name": "bitget-nfi-5x-demo",
  "initial_state": "running",
  "force_entry_enable": false
}
EOFCONFIG

echo -e "${GREEN}[3/6] 下载 1d 日线数据...${NC}"
mkdir -p user_data/data/bitget/futures
if [ -n "$PROXY_URL" ]; then
    HTTP_PROXY="$PROXY_URL" HTTPS_PROXY="$PROXY_URL" python3 download_1d_data.py 2>&1 || echo "1d数据下载失败，可能已存在或网络问题，继续部署..."
else
    python3 download_1d_data.py 2>&1 || echo "1d数据下载失败，可能已存在或网络问题，继续部署..."
fi

echo -e "${GREEN}[4/6] 停止旧容器...${NC}"
docker stop bitget-demo 2>/dev/null || true
docker rm bitget-demo 2>/dev/null || true
docker stop nfi-updater-bitget 2>/dev/null || true
docker rm nfi-updater-bitget 2>/dev/null || true

echo -e "${GREEN}[5/6] 启动机器人...${NC}"
# 构建代理环境变量
PROXY_ENV=""
if [ -n "$PROXY_URL" ]; then
    PROXY_ENV="-e HTTP_PROXY=$PROXY_URL -e HTTPS_PROXY=$PROXY_URL -e http_proxy=$PROXY_URL -e https_proxy=$PROXY_URL"
fi

docker run -d \
  --name bitget-demo \
  --network host \
  $PROXY_ENV \
  -v "$SCRIPT_DIR:/work" \
  -v "$SCRIPT_DIR/user_data/data:/work/user_data/data" \
  -w /work \
  --restart unless-stopped \
  freqtrade_with_numba trade \
    --strategy NostalgiaForInfinityX7_5x \
    --strategy-path /work \
    --config configs/config-bitget-live.json \
    --db-url sqlite:////work/user_data/bitget-demo-tradesv3.sqlite \
    --log-file user_data/logs/bitget-demo.log

echo -e "${GREEN}[6/6] 启动自动更新器 + 验证...${NC}"

# 构建并启动 nfi-updater
docker build -t nfi-updater-bitget -f docker/Dockerfile.updater.bitget . 2>/dev/null || true
UPDATER_PROXY_ENV=""
if [ -n "$PROXY_URL" ]; then
    UPDATER_PROXY_ENV="-e http_proxy=$PROXY_URL -e https_proxy=$PROXY_URL -e HTTP_PROXY=$PROXY_URL -e HTTPS_PROXY=$PROXY_URL"
fi

docker run -d \
  --name nfi-updater-bitget \
  --network host \
  $UPDATER_PROXY_ENV \
  -e TZ=Asia/Shanghai \
  -e NFI_UPDATE_CRON="0 10 * * *" \
  -v "$SCRIPT_DIR:/data" \
  -v "/var/run/docker.sock:/var/run/docker.sock" \
  --restart unless-stopped \
  nfi-updater-bitget 2>/dev/null || echo "nfi-updater 启动失败，机器人可独立运行"

# 检查容器状态
if docker ps | grep -q bitget-demo; then
    echo ""
    echo -e "${GREEN}==========================================${NC}"
    echo -e "${GREEN} 部署成功！${NC}"
    echo -e "${GREEN}==========================================${NC}"
    echo ""
    echo "容器状态:"
    docker ps --format "  {{.Names}}: {{.Status}}" | grep -E "bitget-demo|nfi-updater"
    echo ""
    echo "配置信息:"
    echo "  策略: NostalgiaForInfinityX7_5x (5倍杠杆)"
    echo "  交易所: Bitget 模拟盘"
    echo "  最大持仓: 6"
    echo "  时间框架: 5m"
    if [ -n "$TELEGRAM_BOT_TOKEN" ]; then
        echo "  Telegram: ✅ 已启用"
    else
        echo "  Telegram: ❌ 未配置"
    fi
    if docker ps | grep -q nfi-updater-bitget; then
        echo "  自动更新: ✅ 已启用 (每天10:00更新)"
    else
        echo "  自动更新: ❌ 未启动"
    fi
    echo ""
    echo "常用命令:"
    echo "  docker logs -f bitget-demo          # 查看日志"
    echo "  docker restart bitget-demo          # 重启"
    echo "  docker stop bitget-demo             # 停止"
    echo "  docker logs -f nfi-updater-bitget   # 查看更新器日志"
    echo ""
else
    echo -e "${RED}启动失败！查看日志:${NC}"
    docker logs --tail 20 bitget-demo 2>&1
    exit 1
fi
