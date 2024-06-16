#!/bin/bash
# Copyright (C) Author: Kriachko Aleksei admin@unixweb.info
# Check if the script is being run as root or by a user in the sudo group
if [[ $EUID -ne 0 ]]; then
  if groups $USER | grep &>/dev/null '\bsudo\b'; then
    echo "Script is being run by a user in the sudo group."
  else
    echo "This script must be run as root or by a user in the sudo group. Exiting."
    exit 1
  fi
fi

# Check if the operating system is supported
if [[ "$(lsb_release -is)" != "Ubuntu" && "$(lsb_release -is)" != "Debian" ]]; then
  echo "This script is only supported on Ubuntu and Debian. Exiting."
  exit 1
fi

# Check if sudo is installed and install it if not
if ! command -v sudo &>/dev/null; then
  echo "sudo is not installed. Installing..."
  apt-get install sudo
fi

# Check if git is installed and install it if not
if ! command -v git &>/dev/null; then
  echo "git is not installed. Installing..."
  sudo apt-get install git
fi

# Define packages to install
packages=("apparmor" "apparmor-utils" "libapache2-mod-apparmor" "auditd")

# Install packages if they are not already installed
for package in "${packages[@]}"; do
  if dpkg -s "$package" >/dev/null 2>&1; then
    echo "$package is already installed."
  else
    echo "Installing $package..."
    if ! sudo apt install -y "$package"; then
      echo "Error installing $package. Exiting."
      exit 1
    fi
  fi
done

# Backup existing AppArmor profiles
if [ -d "/etc/apparmor.d" ]; then
  echo "Backing up existing AppArmor profiles..."
  if ! sudo cp -r /etc/apparmor.d /root/apparmor.d; then
    echo "Error backing up existing AppArmor profiles. Exiting."
    exit 1
  fi
else
  echo "No existing AppArmor profiles found."
fi

# Define patterns to match files to remove
patterns=("/etc/apparmor.d/tunables/home" "/etc/apparmor.d/usr.bin.doveconf" "/etc/apparmor.d/usr.bin.freshclam" "/etc/apparmor.d/usr.lib.dovecot.*" "/etc/apparmor.d/usr.sbin.apache2" "/etc/apparmor.d/usr.sbin.apache2.dpkg-dist" "/etc/apparmor.d/usr.sbin.clamd" "/etc/apparmor.d/usr.sbin.dovecot" "/etc/apparmor.d/usr.sbin.exim4" "/etc/apparmor.d/usr.sbin.mysqld" "/etc/apparmor.d/usr.sbin.nginx" "/etc/apparmor.d/usr.sbin.php-fpm8.1" "/etc/apparmor.d/usr.sbin.proftpd")

# Remove files if they exist
for pattern in "${patterns[@]}"; do
  files=$(find / -path "$pattern" 2>/dev/null)
  for file in $files; do
    if [ -f "$file" ]; then
      echo "Removing $file..."
      if ! sudo rm -rf "$file"; then
        echo "Error removing $file. Exiting."
        exit 1
      fi
    else
      echo "$file does not exist."
    fi
  done
done

# Clone AppArmor profiles from GitHub
# Create a temporary directory
temp_dir=$(mktemp -d)

# Clone AppArmor profiles from GitHub into the temporary directory
echo "Cloning AppArmor profiles from GitHub..."
if ! sudo git clone https://github.com/unixweb-info/apparmor.d.git "$temp_dir"; then
  echo "Error cloning AppArmor profiles from GitHub. Exiting."
  exit 1
fi

# Move the cloned files into /etc/apparmor.d
echo "Moving AppArmor profiles into /etc/apparmor.d..."
sudo rsync -a "$temp_dir/" /etc/apparmor.d/

# Remove the temporary directory
sudo rm -r "$temp_dir"

# Removing the README.md, .gitattributes files and the .git directory from the /etc/apparmor.d folder.
sudo rm -rf /etc/apparmor.d/{README.md,.gitattributes,.git} 


# Restart services
echo "Restarting services..."
if ! sudo systemctl restart apparmor auditd; then
  echo "Error restarting services. Exiting."
  exit 1
fi

# Enforce AppArmor profiles
profiles=("/etc/apparmor.d/usr.sbin.dovecot" "/etc/apparmor.d/usr.bin.freshclam" "/etc/apparmor.d/usr.sbin.clamd" "/etc/apparmor.d/usr.sbin.exim4" "/etc/apparmor.d/usr.sbin.apache2" "/etc/apparmor.d/usr.sbin.mysqld" "/etc/apparmor.d/usr.sbin.nginx" "/etc/apparmor.d/usr.sbin.php-fpm8.1" "/etc/apparmor.d/usr.sbin.proftpd")

for profile in "${profiles[@]}"; do
  if [ -f "$profile" ]; then
    echo "Enforcing $profile..."
    if ! sudo aa-enforce "$profile"; then
      echo "Error enforcing $profile. Exiting."
      exit 1
    fi
  else
    echo "$profile does not exist."
  fi
done

# Restart services
echo "Restarting services..."
if ! sudo systemctl restart clamav-daemon clamav-freshclam mysql nginx dovecot proftpd php8.1-fpm apache2; then
  echo "Error restarting services. Exiting."
  exit 1
fi

# Display AppArmor status
echo "Displaying AppArmor status..."
if ! sudo aa-status; then
  echo "Error displaying AppArmor status. Exiting."
  exit 1
fi
