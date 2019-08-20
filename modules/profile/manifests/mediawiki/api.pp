# == Class profile::mediawiki::api
#
# Specific settings for the mediawiki API servers
class profile::mediawiki::api {
    # Using fastcgi we need more local ports
    sysctl::parameters { 'raise_port_range':
        values   => { 'net.ipv4.local_port_range' => '22500 65535', },
        priority => 90,
    }
}
