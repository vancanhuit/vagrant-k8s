#!/usr/bin/env bash

set -euo pipefail

sudo sed -i '/swap/s/^/# /' /etc/fstab
