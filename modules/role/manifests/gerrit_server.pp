# server running Gerrit code review software
# https://en.wikipedia.org/wiki/Gerrit_%28software%29
#
class role::gerrit_server {

    include ::standard
    include ::profile::gerrit::server

    interface::ip { 'role::gerrit::server_ipv4':
        interface => 'eth0',
        address   => $ipv4,
        prefixlen => '32',
    }

    if $ipv6 != undef {
        interface::ip { 'role::gerrit::server_ipv6':
            interface => 'eth0',
            address   => $ipv6,
            prefixlen => '128',
        }
    }


}
