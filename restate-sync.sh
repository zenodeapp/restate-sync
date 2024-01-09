if [ -z "$1" ] || [ -z "$2" ]; then
    echo ""
    echo "Usage:   sh $0 <BINARY_NAME> <NODE_DIR> [HEIGHT_INTERVAL] [RPC_SERVER_1] [RPC_SERVER_2]"
    echo ""
    echo "Example: sh refresh-state-sync.sh genesisd .genesis 1000 \"https://26657.genesisl1.org:443\""
    echo "         This will refresh the state sync using a trust height of LATEST_BLOCK - 1000 and"
    echo "         sets the RPC server addresses to https://26657.genesisl1.org:443"
    echo ""
    echo "  <NODE_DIR> should only be the name of the node directory, not a path (e.g. .gaia, .genesis, .cronos, .osmosisd etc.)."
    echo "  [HEIGHT_INTERVAL] is optional (default: 2000)."
    echo "  [RPC_SERVER_1] is optional (if none is given then the script will try to use the RPC SERVER url in your config.toml file)."
    echo "  [RPC_SERVER_2] is optional (default: [RPC_SERVER_1])."
    exit 1
fi

BINARY_NAME=$1
NODE_DIR=$2
HEIGHT_INTERVAL=${3:-2000}
RPC_SERVER_1=$4
RPC_SERVER_2=${5:-$RPC_SERVER_1}
CONFIG_PATH=~/$NODE_DIR/config
RPC_SERVER_PROVIDED=false

# Check if the node directory exists
if [ ! -d "$HOME/$NODE_DIR" ]; then
    echo "The folder $HOME/$NODE_DIR does not exist."
    exit 1
fi

# Get RPC server from config if RPC_SERVER_1 is empty
if [ -z "$RPC_SERVER_1" ]; then
    RPC_SERVER_1=$(grep "rpc_servers" $CONFIG_PATH/config.toml | awk -F '[=,]' '{print $2}' | tr -d '[:space:]' | sed 's/"//g')

    if [ -z "$RPC_SERVER_1" ]; then
        echo "No RPC server has been set up. Make sure to provide one when running this script or adapt the config.toml file yourself before trying again."
        exit 1
    fi
else
    RPC_SERVER_PROVIDED=true
fi

echo "WARNING: State-syncing will wipe the $HOME/$NODE_DIR/data folder (a backup of priv_validator_state.json will be made though)."
echo "Service $BINARY_NAME will get halted using systemctl stop $BINARY_NAME, if this doesn't match your setup, make sure to halt the node yourself first!"
echo ""
read -p "Do you want to continue? (y/N): " ANSWER
ANSWER=$(echo "$ANSWER" | tr 'A-Z' 'a-z')  # Convert to lowercase

if [ "$ANSWER" != "y" ]; then
    echo "Aborted."
    exit 1
fi

# Stop process
systemctl stop $BINARY_NAME

# Back up validator state
cp ~/$NODE_DIR/data/priv_validator_state.json ~/$NODE_DIR/priv_validator_state.json.bak

LATEST_HEIGHT=$(curl -s $RPC_SERVER_1/block | jq -r .result.block.header.height); \
TRUST_HEIGHT=$((LATEST_HEIGHT - $HEIGHT_INTERVAL)); \
TRUST_HASH=$(curl -s "$RPC_SERVER_1/block?height=$BLOCK_HEIGHT" | jq -r .result.block_id.hash)

sed -i '/^\[statesync\]/,/^enable = / s/enable = .*/enable = true/' $CONFIG_PATH/config.toml
sed -i 's/trust_height = .*/trust_height = '$TRUST_HEIGHT'/' $CONFIG_PATH/config.toml
sed -i 's/trust_hash = .*/trust_hash = "'"$TRUST_HASH"'"/' $CONFIG_PATH/config.toml

# Only set the RPC server if we provided one
if $RPC_SERVER_PROVIDED; then
  sed -i 's#rpc_servers = .*#rpc_servers = "'"$RPC_SERVER_1,$RPC_SERVER_2"'"#' $CONFIG_PATH/config.toml
fi

# Wipe data
$BINARY_NAME tendermint unsafe-reset-all

# Move backed up validator state back
mv ~/$NODE_DIR/priv_validator_state.json.bak ~/$NODE_DIR/data/priv_validator_state.json

echo ""
echo "New trust_height set to $TRUST_HEIGHT with trust_hash: $TRUST_HASH."
echo "You can now turn on your node again using '$BINARY_NAME start' or 'systemctl start $BINARY_NAME'!"