#!/bin/bash
#curl -s https://raw.githubusercontent.com/regbo/lfp-scripts/main/new_server.sh | bash

echo "Starting the new server setup script"
cd ~

# Update the system
sudo apt-get update -y

echo ""
echo "Installing unattended-upgrades..."
# Install and setup unattended-upgrades
sudo apt-get install unattended-upgrades -y

# Edit the 50unattended-upgrade file
sudo sed -i 's|//\t"${distro_id}:${distro_codename}-security";|\t"${distro_id}:${distro_codename}-security";|g' /etc/apt/apt.conf.d/50unattended-upgrades
sudo sed -i 's|//\t"${distro_id}:${distro_codename}-updates";|\t"${distro_id}:${distro_codename}-updates";|g' /etc/apt/apt.conf.d/50unattended-upgrades
sudo sed -i 's|//Unattended-Upgrade::AutoFixInterruptedDpkg "false";|Unattended-Upgrade::AutoFixInterruptedDpkg "true";|g' /etc/apt/apt.conf.d/50unattended-upgrades
sudo sed -i 's|//Unattended-Upgrade::Remove-Unused-Dependencies "false";|Unattended-Upgrade::Remove-Unused-Dependencies "true";|g' /etc/apt/apt.conf.d/50unattended-upgrades
sudo sed -i 's|//Unattended-Upgrade::Automatic-Reboot "false";|Unattended-Upgrade::Automatic-Reboot "true";|g' /etc/apt/apt.conf.d/50unattended-upgrades

# Edit the 10periodic file
TEMP_FILE=$(mktemp)

cat > $TEMP_FILE << EOF
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "1";
EOF

sudo sh -c "cat ${TEMP_FILE} > /etc/apt/apt.conf.d/10periodic"
rm -f $TEMP_FILE

sudo /etc/init.d/unattended-upgrades restart


echo ""
echo "Installing fail2ban for SSHD..."
# Install and setup fail2ban for SSHD
sudo apt-get install fail2ban -y
# Copy the default jail.conf file to a new file called jail.local
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
# Change the ban time from 600 seconds (10 min) to 86,400 seconds (1 day) :)
perl -pi -e 's/bantime  = 10m/bantime  = 1440m/g' /etc/fail2ban/jail.local
# Change the find time from 600 seconds (10 min) to 3,600 seconds (1 hour)
perl -pi -e 's/findtime  = 10m/findtime  = 60m/g' /etc/fail2ban/jail.local
sudo service fail2ban restart


echo ""
echo "Installing tailscale..."
curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/focal.gpg | sudo apt-key add -
curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/focal.list | sudo tee /etc/apt/sources.list.d/tailscale.list
sudo apt-get update
sudo apt-get install tailscale
echo 'net.ipv4.ip_forward = 1' | sudo tee -a /etc/sysctl.conf
echo 'net.ipv6.conf.all.forwarding = 1' | sudo tee -a /etc/sysctl.conf
sudo sysctl -p /etc/sysctl.conf

echo ""
echo "Installing docker-ce..."
sudo apt-get remove -y docker docker-engine docker.io containerd runc
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install --fix-missing -y docker-ce docker-ce-cli containerd.io

echo "Installing docker-compose..."
sudo apt-get install docker-compose -y

if [ "$EUID" -ne 0 ]; then
  echo "Adding $USER to docker group"
  sudo usermod -aG docker $USER
fi
