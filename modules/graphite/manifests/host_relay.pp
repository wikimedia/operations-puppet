# == Class: graphite::host_relay
#
# Install a local carbon-c-relay listening on localhost:2003/tcp to relay
# graphite metrics to all $clusters, with load-balancing and failover.
#
# graphite::host_relay { 'local':
#     clusters => {
#         'eqiad' => [
#              'graphite1001.eqiad.wmnet:2003',
#              'graphite1003.eqiad.wmnet:2003',
#              ],
#     }

class graphite::host_relay( $clusters ) {
    $queuesize = 100000

    package { 'carbon-c-relay':
        ensure => present,
    }

    file { '/etc/carbon-c-relay.conf':
        content => template('graphite/host-relay.conf.erb'),
        mode    => '0444',
        notify  => Exec['carbon-c-relay_reload'],
    }

    file { '/etc/default/carbon-c-relay':
        content => "DAEMON_ARGS='-i lo -f /etc/carbon-c-relay.conf -q ${queuesize}'",
        mode    => '0444',
        notify  => Service['carbon-c-relay'],
    }

    exec { 'carbon-c-relay_reload':
        path        => '/usr/sbin:/usr/bin:/sbin:/bin',
        command     => 'service carbon-c-relay reload',
        onlyif      => 'carbon-c-relay -t -f /etc/carbon-c-relay.conf < /dev/null',
        refreshonly => true,
    }

    service { 'carbon-c-relay':
        ensure => 'running',
    }
}
