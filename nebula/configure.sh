#!/bin/bash
set -e
[ "$UID" -eq 0 ] || exec sudo bash "$0" "$@"
mkdir -p /root/nebula
cd /root/nebula
echo "downloading config"
curl -s -L https://github.com/slackhq/nebula/raw/master/examples/config.yml --output config.yml
#set pki ca
pkiKey=ca
pkiPath=/root/nebula/ca.crt
pkiKey=$pkiKey pkiPath=$pkiPath yq eval '.pki.[strenv(pkiKey)] = strenv(pkiPath)' --inplace config.yml
if [ ! -f "$pkiPath" ]; then
	echo "$pkiKey not found:$pkiPath"
    exit 1
fi
#set pki cert
pkiKey=cert
pkiPath=/root/nebula/host.crt
pkiKey=$pkiKey pkiPath=$pkiPath yq eval '.pki.[strenv(pkiKey)] = strenv(pkiPath)' --inplace config.yml
if [ ! -f "$pkiPath" ]; then
	echo "$pkiKey not found:$pkiPath"
    exit 1
fi
#set pki key
pkiKey=key
pkiPath=/root/nebula/host.key
pkiKey=$pkiKey pkiPath=$pkiPath yq eval '.pki.[strenv(pkiKey)] = strenv(pkiPath)' --inplace config.yml
if [ ! -f "$pkiPath" ]; then
	echo "$pkiKey not found:$pkiPath"
    exit 1
fi
#listen on all
value="[::]" yq eval '.listen.host = strenv(value)' --inplace config.yml
#update mtu
yq eval '.tun.mtu = 1500' --inplace config.yml
#allow inbound any
yq eval 'del(.firewall.inbound)' --inplace config.yml
yq eval '.firewall.inbound.[0].port = "any"' --inplace config.yml
yq eval '.firewall.inbound.[0].proto = "any"' --inplace config.yml
yq eval '.firewall.inbound.[0].host = "any"' --inplace config.yml
#remove static_host_map
yq eval 'del(.static_host_map)' --inplace config.yml
nebula_ip_added=false
while true
do	
	echo "enter lighthouse nebula ip, or blank to complete"
	read nebula_ip
	if [ -z "$nebula_ip" ] && [ $nebula_ip_added != true ]; then
		echo "Error: at least one lighthouse nebula ip required"
		exit 1;
	elif [ -z "$nebula_ip" ]; then
		break
	else
		nebula_ip_added=true
	fi
	#read public
	echo "enter lighthouse public address"
	read public_address
	if [ -z "$public_address" ]; then
		echo "Error: a lighthouse public address is required"
		exit 1;
	fi
	nebula_ip=$nebula_ip public_address=$public_address yq eval '.static_host_map.[strenv(nebula_ip)] += [strenv(public_address)+":4242"]' --inplace config.yml
done
yq eval 'del(.lighthouse.hosts)' --inplace config.yml
lighthouse_hosts=$(yq eval '.static_host_map.[] | path | .[-1]' config.yml)
echo "is this node a lighthouse?"
read am_lighthouse
if [[ $(fgrep -ix $am_lighthouse <<< "true") ]]; then
    yq eval '.lighthouse.am_lighthouse = true' --inplace config.yml
else
	yq eval '.lighthouse.am_lighthouse = false' --inplace config.yml
	echo "$lighthouse_hosts" | while read lighthouse_host ; do
	   lighthouse_host=$lighthouse_host yq eval '.lighthouse.hosts += [strenv(lighthouse_host)]' --inplace config.yml
	done
	ufw --force reset
	ufw allow 22/tcp
	ufw allow in on nebula1 to any port 2376 proto tcp
	ufw allow in on nebula1 to any port 7946 proto tcp
	ufw allow in on nebula1 to any port 7946 proto udp
	ufw allow in on nebula1 to any port 4789 proto udp
	ufw allow in on nebula1 to any proto esp
	ufw --force enable
fi
serviceFile=/etc/systemd/system/nebula.service
rm -f $serviceFile
cat > $serviceFile <<- EOM
[Unit]
Description=Nebula overlay networking tool

After=basic.target network.target network-online.target
Before=sshd.service
Wants=basic.target network-online.target

[Service]
ExecReload=/bin/kill -HUP $MAINPID
ExecStartPre=/bin/sh -c 'until ping -c1 8.8.8.8; do sleep 1; done;'
ExecStart=/root/nebula/nebula -config /root/nebula/config.yml
Restart=always
SyslogIdentifier=nebula

[Install]
WantedBy=multi-user.target
EOM
chmod 664 $serviceFile
sudo systemctl daemon-reload
sudo systemctl enable nebula.service
sudo systemctl start nebula.service

#print
yq e config.yml
