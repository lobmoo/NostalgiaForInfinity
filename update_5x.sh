#!/bin/bash
# NFI 5x杠杆自动更新脚本
set -e
cd /home/wwk/workspace/git-project/NostalgiaForInfinity

echo "1. 拉取上游更新..."
git fetch upstream main 2>/dev/null || git fetch origin main
git checkout FETCH_HEAD -- NostalgiaForInfinityX7.py

echo "2. 生成5x杠杆版本..."
cp NostalgiaForInfinityX7.py NostalgiaForInfinityX7_5x.py
sed -i 's/futures_mode_leverage = 3.0/futures_mode_leverage = 5.0/g' NostalgiaForInfinityX7_5x.py
sed -i 's/futures_mode_leverage_rebuy_mode = 3.0/futures_mode_leverage_rebuy_mode = 5.0/g' NostalgiaForInfinityX7_5x.py
sed -i 's/futures_mode_leverage_grind_mode = 3.0/futures_mode_leverage_grind_mode = 5.0/g' NostalgiaForInfinityX7_5x.py
sed -i 's/class NostalgiaForInfinityX7(/class NostalgiaForInfinityX7_5x(/' NostalgiaForInfinityX7_5x.py

echo "3. 提交更新..."
git add NostalgiaForInfinityX7.py NostalgiaForInfinityX7_5x.py
git commit -m "sync upstream + 5x leverage" || echo "nothing to commit"

echo "4. 推送到fork..."
git push origin main

echo "5. 重启freqtrade..."
docker compose restart freqtrade

echo "更新完成!"
