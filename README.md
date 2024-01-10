# Restate Sync

A State Sync Refresher usable in Tendermint or CometBFT-based protocols. This wipes the whole data folder and recalibrates the state-sync to a more recent height while making sure to backup and restore the priv_validator_state.json file.

This has been written by ZENODE and is licensed under the MIT-license (see [LICENSE.md](./LICENSE.md)).

## Overview

Running out of space happens to all of us, especially when you're running multiple nodes that grow day-by-day. When [State Sync](https://docs.tendermint.com/v0.34/tendermint-core/state-sync.html) arrived, many got very enthusiastic to how quickly one could now join a network, without needing a ton of space.

But, even a state-synced node could eventually become too large in size. This small repository aims to solve this problem by providing a script that somewhat automates the steps required to _recalibrate_ a state-sync to a more recent height.

### [restate-sync.sh](restate-sync.sh)

```
Usage:   sh restate-sync.sh <BINARY_NAME> <NODE_DIR> [HEIGHT_INTERVAL] [RPC_SERVER_1] [RPC_SERVER_2]

Example: sh restate-sync.sh genesisd .genesis 1000 "https://26657.genesisl1.org:443"
         This will refresh the state sync using a trust height of LATEST_BLOCK - 1000 (rounded)
         and sets the RPC server addresses to https://26657.genesisl1.org:443

  <NODE_DIR> should only be the name of the node directory, not a path (e.g. .gaia, .genesis, .cronos, .osmosisd etc.).
  [HEIGHT_INTERVAL] is optional (default: 2000).
  [RPC_SERVER_1] is optional (if none is given then the script will try to use the RPC SERVER url in your config.toml file).
  [RPC_SERVER_2] is optional (default: [RPC_SERVER_1]).
```

### Data wipe

> [!CAUTION]
> The node's **data-folder will get wiped** using `<BINARY_NAME> tendermint unsafe-reset-all`!

While it does try to stop the node service, create a backup of and restores the _priv_validator_state.json_ file, we encourage you to stop it yourself and create a backup in case of the small chance your setup _or_ chain differs from the _norm_. Though, rest assured, the script will tell you exactly what will happen before it does anything reckless.

Here follows an example warning message when one runs `sh restate-sync.sh genesisd .genesis`:
```
WARNING: - Service 'genesisd' will get halted using 'systemctl stop genesisd'.
         - A backup and restore of /root/.genesis/data/priv_validator_state.json will be performed.
         - State-syncing will wipe the /root/.genesis/data folder.

If any of this doesn't match your setup, make sure to halt and/or backup the node yourself before continuing!

Do you want to continue? (y/N): 
```

### Breaking the two RPC server limit

> [!TIP]
> If you want to add more than two RPCs, then **manually configure the rpc_servers-field** and **leave [RPC_SERVER_1] and [RPC_SERVER_2] blank**.

This script is limited to setting two RPC URIs in the `rpc_servers`-field of your config.toml file. If you want to add more, then manually add the RPC URIs in your config.toml file and do not call the script with either of the `[RPC_SERVER_1]` or `[RPC_SERVER_2]` arguments. This will let the script parse the first rpc server frm the `rpc_servers`-field, uses this to query the latest block height _and_ leaves the field untouched.

## Cronjob idea

Something for later down the line _or_ something you could create is a cronjob that periodically checks the size of the node directory and runs the [restate-sync.sh](restate-sync.sh) script whenever a certain threshold (in GBs) gets met.

</br>

<p align="right">— ZEN</p>
<p align="right">Copyright (c) 2024 ZENODE</p>
