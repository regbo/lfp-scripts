#!/bin/bash
#curl -s https://raw.githubusercontent.com/regbo/lfp-scripts/main/new_server.sh | sudo bash

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
sudo cat >/etc/apt/apt.conf.d/10periodic <<EOL
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "1";
EOL

/etc/init.d/unattended-upgrades restart


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
echo "Installing docker-ce..."
# Download Docker
curl -fsSL get.docker.com -o get-docker.sh
# Install Docker using the stable channel (instead of the default "edge")
CHANNEL=stable sh get-docker.sh
# Remove Docker install script
rm get-docker.sh

echo "Installing docker-compose..."
sudo apt-get install docker-compose -y

if [ "$EUID" -ne 0 ]; then
  echo "Adding $USER to docker group"
  sudo usermod -aG docker $USER
fi
