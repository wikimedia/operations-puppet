## This file is managed by Puppet
## Do not edit

# we need to set the protocol before loading
# the default profile
protocol unix,inet,inet6,netlink

include /etc/firejail/default.profile

blacklist /root
x11 xpra

