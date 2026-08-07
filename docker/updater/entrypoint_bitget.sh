#!/bin/bash
# Entrypoint for Bitget 5x strategy updater
set -e

echo "================================================"
echo " NFI Updater starting (Bitget 5x)"
echo " Strategy  : NostalgiaForInfinityX7_5x"
echo " Exchange  : bitget"
echo " Cron      : ${NFI_UPDATE_CRON:-0 10 * * *}"
echo " Timezone  : ${TZ:-UTC}"
echo "================================================"

echo "${NFI_UPDATE_CRON:-0 10 * * *} /scripts/update_nfi_bitget.sh >> /proc/1/fd/1 2>&1" | crontab -
crond -l 8

echo "Running initial update check..."
/scripts/update_nfi_bitget.sh

# Keep the container running
exec /scripts/nfi_watcher.sh
