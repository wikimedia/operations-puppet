# == Class: varnish::htcppurger
#
# Creates a vhtcpd daemon on the host, which relays "HTCP" multicast packets
# into PURGEs to local varnish instances.
#
# === Parameters:
# [*mc_addrs*]
#   Required - Array of multicast addresses to subscribe.
#
# [*varnishes*]
#   Required - Array of 'IP:Port[,delay]' for local varnish instances to forward to.
#
# [*host_regex*]
#   Required - Regex filter for hosts to PURGE, empty string '' for no filtering
#
# === Multicast assignments:
#   239.128.0.112 - text (legacy: all HTCP used this address)
#   239.128.0.113 - upload
#   239.128.0.114 - maps
#
#  --
#  Note that due to low-level details of how multicast works, it's best if we
#  avoid assigning separate multicast addressess anywhere in our
#  infrastructure which are identical in the bottom 23 bits and differ only in
#  the top 5 bits (the IPv4 multicast space is 28 bits total), as those will
#  effectively alias each other at layer 2 even if they're filtered and used
#  independently at higher layers...
#  We should probably start registering and tracking the multicast we use
#  somewhere centrally...
#  --
#

class varnish::htcppurger(
    $mc_addrs,
    $host_regex,
    $varnishes,
) {
    package { 'vhtcpd':
        ensure => present,
    }

    if $host_regex != '' {
        $regex_arg = " -r ${host_regex}"
    }
    else {
        $regex_arg = ''
    }

    file { '/etc/default/vhtcpd':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        require => Package['vhtcpd'],
        content => template('varnish/vhtcpd-default.erb'),
    }

    service { 'vhtcpd':
        ensure     => running,
        require    => Package['vhtcpd'],
        subscribe  => File['/etc/default/vhtcpd'],
        hasstatus  => true,
        hasrestart => true,
    }

    nrpe::monitor_service { 'vhtcpd':
        description  => 'Varnish HTCP daemon',
        nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 1:1 -u vhtcpd -a vhtcpd',
        notes_url    => 'https://wikitech.wikimedia.org/wiki/Varnish',
    }
}
