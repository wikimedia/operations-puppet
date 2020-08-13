# system directories
# TODO: FirejailCommand should blacklist these
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

# TODO: investigate upstreaming this into FirejailCommand
caps.drop all

# MediaWiki private stuff
blacklist /srv/mediawiki/private
