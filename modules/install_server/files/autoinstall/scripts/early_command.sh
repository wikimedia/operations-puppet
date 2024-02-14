#!/bin/sh

set -e

## redo network configuration statically
IFACE=$(ip -4 route list 0/0 | sed -r 's/.*dev ([^ ]*) .*/\1/' | head -1)
IP="$(ip address show dev $IFACE | egrep '^[[:space:]]+inet ' | cut -d ' ' -f 6 | cut -d '/' -f 1)"
cat > /tmp/static_net.cfg <<EOF
d-i netcfg/get_ipaddress string $IP
d-i netcfg/disable_autoconfig boolean true
EOF
debconf-set-selections /tmp/static_net.cfg
kill-all-dhcp; netcfg

# Workaround netcfg not handling "netcfg/get_netmask string 255.255.255.255"
# https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=1064005
# For routed Ganeti.
# Doesn't scale well, ideally there should be a better way to detect if it's routed or not.
case $IP in
10.192.2[4-5].*)
  MODE=routed
  GATEWAY=10.192.24.1
  ;;
*)
  MODE=switched
  ;;
esac

if [ "$MODE" = "routed" ]; then
    ip addr del $IP dev $IFACE
    ip addr add $IP/32 dev $IFACE
    ip route add $GATEWAY dev $IFACE scope link
    ip route add default via $GATEWAY
fi


# install the network-console udeb, providing SSH access to the installer
# which is useful for debugging (see also network-console settings)
anna-install network-console

# preseed the correct wikimedia repository location
if [ -f /usr/share/keyrings/ubuntu-archive-keyring.gpg ]; then
	SUITE=$(debconf-get mirror/suite)-wikimedia
	COMPONENTS="main universe thirdparty"
else
	#SUITE=$(debconf-get mirror/codename)-wikimedia # is set later in the installation process
	SUITE=$(cat /etc/default-release)-wikimedia
	COMPONENTS="main backports thirdparty"
fi
echo d-i apt-setup/local0/repository string deb http://apt.wikimedia.org/wikimedia $SUITE $COMPONENTS > /tmp/apt_repository.cfg
debconf-set-selections /tmp/apt_repository.cfg

# apt-setup doesn't allow us to set up pinning and hence everything we install
# with apt-install bypasses pinning. hack around this by creating a
# base-installer early hook that does this right before apt-get update
cat > /usr/lib/base-installer.d/10aptpinning <<EOF
#!/bin/sh
set -e

APT_PREFDIR=/target/etc/apt/preferences.d
[ ! -d "\$APT_PREFDIR" ] && mkdir -p "\$APT_PREFDIR"

cat >\$APT_PREFDIR/wikimedia.pref <<EOT
Package: *
Pin: release o=Wikimedia
Pin-Priority: 1001
EOT
EOF
chmod +x /usr/lib/base-installer.d/10aptpinning
