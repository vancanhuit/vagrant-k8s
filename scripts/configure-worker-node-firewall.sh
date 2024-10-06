#!/usr/bin/env bash

set -euo pipefail

ufw allow 10250/tcp
ufw allow 10256/tcp
ufw allow 30000:32767/tcp

ufw allow 179/tcp
ufw allow 4789/udp
ufw allow 5473/tcp
ufw allow 51820:51821/tcp
