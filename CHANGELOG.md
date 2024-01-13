# Changelog

## v1.0.0 - 2024-01-13

First release of **Restate Sync**. This version should work with any Tendermint- or CometBFT based protocol as long as the format of the **[statesync]** settings in the _config.toml_-file is:

```
[statesync]
enable = ...
rpc_servers = ...
trust_height = ...
trust_hash = ...
```

### Added
- [restate-sync.sh](restate-sync.sh); script that recalibrates the state sync settings to a more recent height.
- [README.md](README.md); explains how to use this tool and what one should expect.
- [MIT License](LICENSE); to allow others to freely incorporate this tool into their own creative endeavors :).

<hr>

<p align="right">— ZEN</p>
<p align="right">Copyright (c) 2024 ZENODE</p>
<p align="right">Last updated on: <i>2024-01-13 (YYYY-MM-DD)</i></p>
