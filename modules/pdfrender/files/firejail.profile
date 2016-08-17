## This file is managed by Puppet
## Do not edit

# we need to set the protocol before loading
# the default profile
protocol unix,inet,inet6,netlink

include /etc/firejail/default.profile

blacklist /root

# Electron uses xvfb as the X11 engine by default, which
# requires setuid root; that is not acceptable for firejail
# so we use the alternative xpra X11 server to avoid this
x11 xpra

