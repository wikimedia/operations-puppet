uid = swift
gid = swift
log file = /var/log/rsyncd.log
pid file = /var/run/rsyncd.pid

[account]
max connections = 2
path = /srv/swift-storage/
read only = false
lock file = /var/lock/account.lock

[container]
max connections = 2
path = /srv/swift-storage/
read only = false
lock file = /var/lock/container.lock

[object]
max connections = 3
path = /srv/swift-storage/
read only = false
lock file = /var/lock/object.lock
