#!/bin/bash
set -e
[ "$UID" -eq 0 ] || exec sudo bash "$0" "$@"
if [ -z "$1" ]; then
	echo "Error: cert name argument not found"
    exit 1
fi
mkdir -p /root/nebula/node-certs
cd /root/nebula
#check key exists
pkiPath=/root/nebula/ca.key
if [ ! -f "$pkiPath" ]; then
	echo "Error: ca key not found:$pkiPath - run '/root/nebula/nebula-cert ca -name \"Myorganization, Inc\"'"
    exit 1
fi
ip_counter_file="ip_counter.txt"
ip_counter=1
if [ -f "$ip_counter_file" ]; then
    X=$(cat $ip_counter_file)
    ip_counter=$(($X + 1))
fi
echo $ip_counter > $ip_counter_file
ip="192.168.69.$ip_counter"
echo $ip
./nebula-cert sign -name "$1-$ip" -ip "$ip/24"
mv ./"$1-$ip.key" /root/nebula/node-certs
mv ./"$1-$ip.crt" /root/nebula/node-certs
