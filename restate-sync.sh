#!/bin/bash

# STATE-SYNC REFRESHER for Tendermint or CometBFT-based protocols.
# https://github.com/zenodeapp/restate-sync
# ZENODE (https://zenode.app)

# This script will refresh the state sync of your node by setting the
# configuration for state-sync to latest_height - height_interval and
# rounds it to the nearest multiple of height_interval. The code makes
# sure to backup and restore the priv_validator_state.json file, before
# it wipes the entire /data folder.

if [ -z "$1" ] || [ -z "$2" ]; then
    echo ""
    echo "Usage:   sh $0 <binary_name> <node_dir_name> [height_interval] [rpc_server_1] [rpc_server_2]"
    echo ""
    echo "Example: sh $0 genesisd .genesis 1000 \"https://26657.genesisl1.org:443\""
    echo "         This will refresh the state sync using a trust height of LATEST_BLOCK - 1000 (rounded)"
    echo "         and ets the RPC server addresses to https://26657.genesisl1.org:443"
    echo ""
    echo "  <node_dir_name> should only be the name of the node directory, not a path (e.g. .gaia, .genesis, .cronos, .osmosisd etc.)."
    echo "  [height_interval] is optional (default: 2000)."
    echo "  [rpc_server_1] is optional (if none is given then the script will try to use the RPC SERVER url in your config.toml file)."
    echo "  [rpc_server_2] is optional (default: [rpc_server_1])."
    exit 1
fi

echo ""

BINARY_NAME=$1
NODE_DIR_NAME=$2
NODE_DIR=$HOME/$NODE_DIR_NAME
HEIGHT_INTERVAL=${3:-2000}
RPC_SERVER_1=$4
RPC_SERVER_2=${5:-$RPC_SERVER_1}
CONFIG_DIR=$NODE_DIR/config
DATA_DIR=$NODE_DIR/data

# Check if the node directory exists
if [ ! -d "$NODE_DIR" ]; then
    echo "The folder $NODE_DIR does not exist."
    exit 1
fi

# Get RPC server from config if RPC_SERVER_1 is empty
if [ -z "$RPC_SERVER_1" ]; then
    RPC_SERVER_1=$(grep "rpc_servers" $CONFIG_DIR/config.toml | awk -F '[=,]' '{print $2}' | tr -d '[:space:]' | sed 's/"//g')

    if [ -z "$RPC_SERVER_1" ]; then
        echo "No RPC server has been set up. Make sure to provide one when running this script or adapt the config.toml file yourself before trying again."
        exit 1
    fi
else
    RPC_SERVER_PROVIDED=true
fi

echo "WARNING: - Service '$BINARY_NAME' will get halted using 'systemctl stop $BINARY_NAME'."
echo "         - A backup and restore of $DATA_DIR/priv_validator_state.json will be performed."
echo "         - State-syncing will wipe the $DATA_DIR folder."
echo ""
echo "If any of this doesn't match your setup, make sure to halt and/or backup the node yourself before continuing!"
echo ""
read -p "Do you want to continue? (y/N): " ANSWER
ANSWER=$(echo "$ANSWER" | tr 'A-Z' 'a-z')  # Convert to lowercase

if [ "$ANSWER" != "y" ]; then
    echo "Aborted."
    exit 1
fi

# Query block height data
LATEST_HEIGHT=$(wget -qO- $RPC_SERVER_1/block | jq -r .result.block.header.height)
TRUST_HEIGHT=$(( ((LATEST_HEIGHT - HEIGHT_INTERVAL) / HEIGHT_INTERVAL) * HEIGHT_INTERVAL )) # This makes sure we round to the nearest multiple of HEIGHT_INTERVAL
TRUST_HASH=$(wget -qO- "$RPC_SERVER_1/block?height=$TRUST_HEIGHT" | jq -r .result.block_id.hash)

if [ "$TRUST_HEIGHT" -le 0 ]; then
  echo "Error: trust_height cannot be less than or equal to zero. Your [TRUST_HEIGHT] might be too large for the current state of the blockchain or there is something wrong with the RPC server(s)."
  exit 1
fi

# Stop process
systemctl stop $BINARY_NAME

# Back up validator state
cp $DATA_DIR/priv_validator_state.json $NODE_DIR/priv_validator_state.json.bak

sed -i '/^\[statesync\]/,/^enable = / s/enable = .*/enable = true/' $CONFIG_DIR/config.toml
sed -i 's/trust_height = .*/trust_height = '$TRUST_HEIGHT'/' $CONFIG_DIR/config.toml
sed -i 's/trust_hash = .*/trust_hash = "'"$TRUST_HASH"'"/' $CONFIG_DIR/config.toml

# Only set the RPC server if we provided one
if [ "$RPC_SERVER_PROVIDED" = true ]; then
  sed -i 's#rpc_servers = .*#rpc_servers = "'"$RPC_SERVER_1,$RPC_SERVER_2"'"#' $CONFIG_DIR/config.toml
fi

# Wipe data
$BINARY_NAME tendermint unsafe-reset-all

# Move backed up validator state back
mv $NODE_DIR/priv_validator_state.json.bak $DATA_DIR/priv_validator_state.json

echo ""
echo "New trust_height set to $TRUST_HEIGHT with trust_hash: $TRUST_HASH."
echo "You can now turn on your node again using '$BINARY_NAME start' or 'systemctl start $BINARY_NAME'!"
