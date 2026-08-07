#!/bin/bash

# Custom updater for Bitget 5x strategy
# Downloads NostalgiaForInfinityX7 from GitHub and creates 5x version

STRATEGY_BASE="NostalgiaForInfinityX7"
STRATEGY_5X="NostalgiaForInfinityX7_5x"
EXCHANGE="bitget"

BASE_DIR="/data"
STRATEGY_BASE_FILE="$BASE_DIR/${STRATEGY_BASE}.py"
STRATEGY_5X_FILE="$BASE_DIR/${STRATEGY_5X}.py"
CONFIGS_DIR="$BASE_DIR/configs"

PAIRLIST_FILE="pairlist-volume-${EXCHANGE}-usdt.json"

TEMP_DIR="/tmp/nfi_update"
REPO_URL="https://raw.githubusercontent.com/iterativv/NostalgiaForInfinity/main"

mkdir -p "$TEMP_DIR" "$CONFIGS_DIR"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo "------------------------------------------------"
echo "Date: $(date)"
echo "Checking for NFI updates (Bitget 5x)..."

CHANGES_DETECTED=false

STATE_DIR="$BASE_DIR/.updater_state_${EXCHANGE}"
mkdir -p "$STATE_DIR"

# --- Downloads a file from GitHub and replaces the local copy if it changed ---
check_and_update() {
    local remote_suffix=$1
    local local_path=$2
    local filename
    filename=$(basename "$local_path")
    local remote_url="$REPO_URL/$remote_suffix"
    local tmp_file="$TEMP_DIR/$filename"

    echo -n "Checking $filename ... "

    if ! wget -q -O "$tmp_file" "$remote_url"; then
        echo -e "${RED}[ERROR] Download failed for $remote_url${NC}"
        return
    fi

    STATE_FILE="$STATE_DIR/${filename}.hash"
    BOT_STATE_FILE="$STATE_DIR/.bot_${filename}.hash"

    REMOTE_HASH=$(md5sum "$tmp_file" | awk '{print $1}')

    if [ -f "$STATE_FILE" ]; then
        LAST_REMOTE_HASH=$(cat "$STATE_FILE")

        if [ "$LAST_REMOTE_HASH" != "$REMOTE_HASH" ]; then
            echo -e "${GREEN}[UPDATED]${NC}"
            cp "$tmp_file" "$local_path"
            echo "$REMOTE_HASH" > "$STATE_FILE"
            CHANGES_DETECTED=true
        else
            LOCAL_HASH=$(md5sum "$local_path" 2>/dev/null | awk '{print $1}')
            if [ -f "$BOT_STATE_FILE" ]; then
                BOT_HASH=$(cat "$BOT_STATE_FILE")
                if [ "$BOT_HASH" != "$LOCAL_HASH" ]; then
                    echo -e "${YELLOW}[STALE] Bot running old code, will restart${NC}"
                    CHANGES_DETECTED=true
                else
                    echo -e "${YELLOW}[OK] Up to date${NC}"
                fi
            else
                echo -e "${YELLOW}[SYNC] First run with bot-state tracking, will restart${NC}"
                CHANGES_DETECTED=true
            fi
        fi
    else
        echo -e "${YELLOW}[INIT] First run, establishing baseline${NC}"
        cp "$tmp_file" "$local_path"
        echo "$REMOTE_HASH" > "$STATE_FILE"
        CHANGES_DETECTED=true
    fi

    rm -f "$tmp_file"
}

# Download the base strategy from GitHub
check_and_update "${STRATEGY_BASE}.py" "$STRATEGY_BASE_FILE"

# If base strategy was updated, create the 5x version
if [ "$CHANGES_DETECTED" = true ]; then
    echo "Creating 5x leverage version..."
    cp "$STRATEGY_BASE_FILE" "$STRATEGY_5X_FILE"

    # Replace class name
    sed -i "s/class NostalgiaForInfinityX7(/class NostalgiaForInfinityX7_5x(/" "$STRATEGY_5X_FILE"

    # Replace leverage values from 3.0 to 5.0
    sed -i 's/futures_mode_leverage = 3\.0/futures_mode_leverage = 5.0/' "$STRATEGY_5X_FILE"
    sed -i 's/futures_mode_leverage_rebuy_mode = 3\.0/futures_mode_leverage_rebuy_mode = 5.0/' "$STRATEGY_5X_FILE"
    sed -i 's/futures_mode_leverage_grind_mode = 3\.0/futures_mode_leverage_grind_mode = 5.0/' "$STRATEGY_5X_FILE"

    echo -e "${GREEN}5x version created successfully.${NC}"
fi

# Check blacklist and pairlist
check_and_update "configs/blacklist-${EXCHANGE}.json"  "$CONFIGS_DIR/blacklist-${EXCHANGE}.json"
check_and_update "configs/${PAIRLIST_FILE}"            "$CONFIGS_DIR/${PAIRLIST_FILE}"

echo "------------------------------------------------"

if [ "$CHANGES_DETECTED" = true ]; then
    echo -e "${GREEN}Updates applied! Restarting freqtrade...${NC}"
    rm -rf "$TEMP_DIR"

    # Restart the bitget-dryrun container
    docker restart bitget-dryrun

    echo "Bot restarted successfully."

    # Record bot state
    for f in "$STRATEGY_5X_FILE" "$CONFIGS_DIR/blacklist-${EXCHANGE}.json" "$CONFIGS_DIR/${PAIRLIST_FILE}"; do
        fname=$(basename "$f")
        if [ -f "$f" ]; then
            md5sum "$f" | awk '{print $1}' > "$STATE_DIR/.bot_${fname}.hash"
        fi
    done
else
    echo -e "${GREEN}No updates found. System is up to date.${NC}"
    rm -rf "$TEMP_DIR"
fi
