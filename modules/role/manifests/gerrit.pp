# server running Gerrit code review software
# https://en.wikipedia.org/wiki/Gerrit_%28software%29
#
class role::gerrit {

    system::role { 'Gerrit': description => "Gerrit server in ${::realm}" }

    include ::standard
    include ::profile::backup::host
    include ::profile::base::firewall
    class { '::profile::gerrit::server':
        ipv4 => hiera('gerrit::service::ipv4'),
        ipv6 => hiera('gerrit::service::ipv6', undef),
    }
}
