# Restate Sync

A State Sync Refresher usable in Tendermint or CometBFT-based protocols. This wipes the whole /data folder and recalibrates the state-sync to a more recent height while making sure to backup and restore the priv_validator_state.json file.

This has been written by ZENODE and is licensed under the MIT-license (see [LICENSE.md](./LICENSE.md)).

## Overview

Running out of space happens to all of us, especially when you're running multiple nodes that grow day-by-day. When [State Sync](https://docs.tendermint.com/v0.34/tendermint-core/state-sync.html) arrived, many got very enthusiastic to how quickly one could now join a network, without needing a ton of space.

But, even a state-synced node could eventually become too large in size. This small repository aims to solve this problem by providing a script that somewhat automates the steps required to _recalibrate_ a state-sync to a more recent height.

### [restate-sync.sh](restate-sync.sh)

```
Usage:   sh restate-sync.sh <BINARY_NAME> <NODE_DIR> [HEIGHT_INTERVAL] [RPC_SERVER_1] [RPC_SERVER_2]

Example: sh restate-sync.sh genesisd .genesis 1000 "https://26657.genesisl1.org:443"
         This will refresh the state sync using a trust height of LATEST_BLOCK - 1000 and
         sets the RPC server addresses to https://26657.genesisl1.org:443

  <NODE_DIR> should only be the name of the node directory, not a path (e.g. .gaia, .genesis, .cronos, .osmosisd etc.).
  [HEIGHT_INTERVAL] is optional (default: 2000).
  [RPC_SERVER_1] is optional (if none is given then the script will try to use the RPC SERVER url in your config.toml file).
  [RPC_SERVER_2] is optional (default: [RPC_SERVER_1]).
```

> [!CAUTION]
> **The node's /data folder will get wiped using `<BINARY_NAME> tendermint unsafe-reset-all`!**
>
> While it does create a backup of the _priv_validator_state.json_ file and tries to stop the node service, we encourage you to make a backup and stop it yourself in case of the small chance of your setup _or_ chain differing from the _norm_. Rest assured, the script will tell exactly what will happen and will ask if you agree to continue.

## Cronjob idea

Something for later down the line _or_ something you could create is a cronjob that periodically checks the size of the node directory and runs the [restate-sync.sh](restate-sync.sh) script whenever a certain threshold (in GBs) gets surpassed.

</br>

<p align="right">— ZEN</p>
<p align="right">Copyright (c) 2024 ZENODE</p>
