#!/usr/bin/env bash

set -euo pipefail

sed -i '/swap/s/^/# /' /etc/fstab
