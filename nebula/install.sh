#!/bin/bash
set -e
[ "$UID" -eq 0 ] || exec sudo bash "$0" "$@"
mkdir -p /root/nebula
cd /root/nebula
if ! command -v curl &> /dev/null
then
    echo "installing curl"
    apt update && apt install -y curl
fi
if ! command -v yq &> /dev/null
then
    echo "installing yq"
    curl -s -L https://glare.vercel.app/mikefarah/yq/linux_amd64 --output /usr/bin/yq
    chmod +x /usr/bin/yq
fi
if [ ! -f "nebula" ] || [ ! -f "nebula-cert" ]; then
	rm -f nebula
	rm -f nebula-cert
	echo "installing nebula"
    curl -s -L https://glare.now.sh/slackhq/nebula/linux-amd64 | tar xvz -C .
fi
