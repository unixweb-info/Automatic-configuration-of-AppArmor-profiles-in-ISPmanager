# Automatic configuration of AppArmor profiles in ISPmanager
 Script for automatic installation and configuration of AppArmor in ISPmanager
## Loading and executing the script

<code>
wget https://raw.githubusercontent.com/unixweb-info/Automatic-configuration-of-AppArmor-profiles-in-ISPmanager/main/apparmor-install-and-setting-in-ispmanager6.sh
chmod +x apparmor-install-and-setting-in-ispmanager6.sh
./apparmor-install-and-setting-in-ispmanager6.sh
</code>

This Bash script performs several operations related to system configuration and package management. Here's a breakdown of what it does:

1. **Checks User Permissions**: The script first checks if it's being run as root or by a user in the sudo group. If not, it exits.

2. **Checks Operating System**: It then checks if the operating system is Ubuntu or Debian, as the script is only supported on these platforms.

3. **Installs sudo and git**: If `sudo` or `git` are not installed, the script installs them.

4. **Installs Specific Packages**: The script defines a list of packages (`apparmor-utils`, `libapache2-mod-apparmor`, `auditd`) and installs them if they are not already installed.

5. **Backs Up Existing AppArmor Profiles**: If there are existing AppArmor profiles, the script backs them up.

6. **Removes Specific Files**: The script defines patterns to match files to remove and removes them if they exist.

7. **Clones AppArmor Profiles from GitHub**: The script clones AppArmor profiles from a GitHub repository into a temporary directory, moves the cloned files into `/etc/apparmor.d`, and then removes the temporary directory.

8. **Restarts Services**: The script restarts the `apparmor` and `auditd` services.

9. **Enforces AppArmor Profiles**: The script enforces specific AppArmor profiles if they exist.

10. **Restarts More Services**: The script restarts several other services (`clamav-daemon`, `clamav-freshclam`, `mysql`, `nginx`, `dovecot`, `proftpd`, `php8.1-fpm`, `apache2`).

11. **Displays AppArmor Status**: Finally, the script displays the status of AppArmor.

Please note that this script should be run with caution, as it makes significant changes to the system configuration. Always ensure you understand what a script does before running it.
