# Prevents firejail from emitting to stderr which ends up collected by HHVM and
# pollutes logstash
quiet

# system directories
blacklist /sbin
blacklist /usr/sbin
blacklist /usr/local/sbin

# system management
blacklist ${PATH}/umount
blacklist ${PATH}/mount
blacklist ${PATH}/fusermount
blacklist ${PATH}/su
blacklist ${PATH}/sudo
blacklist ${PATH}/xinput
blacklist ${PATH}/evtest
blacklist ${PATH}/xev
blacklist ${PATH}/strace
blacklist ${PATH}/nc
blacklist ${PATH}/ncat

blacklist /etc/shadow
blacklist /etc/ssh
blacklist /root
blacklist /home
noroot
caps.drop all
seccomp
net none
private-dev
