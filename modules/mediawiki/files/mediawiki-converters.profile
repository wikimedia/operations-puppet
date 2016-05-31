
# This blacklists the sbin directories and admin tools like sudo
include /etc/firejail/disable-mgmt.inc

blacklist /etc/shadow
blacklist /etc/ssh
blacklist /root
blacklist /home
noroot
caps.drop all
seccomp
net none
private-dev
