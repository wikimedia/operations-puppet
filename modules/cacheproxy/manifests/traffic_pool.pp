# == Class cacheproxy::traffic_pool
#
# Manages pooling/depooling of servers in conftool
# upon startup/shutdown.
#
#
class cacheproxy::traffic_pool {
    $varlib_path = '/var/lib/traffic-pool'
    # note: we can't use 'service' because we don't want to 'ensure =>
    # stopped|running', but we still need to enable it
    systemd::unit { 'traffic-pool.service':
        ensure => present,
        content => template('cacheproxy/traffic-pool.service.erb'),
    }

    file { $varlib_path:
        ensure => directory,
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
    }

    exec { 'systemd enable traffic-pool':
        command     => '/bin/systemctl enable traffic-pool.service',
        unless      => '/bin/systemctl is-enabled traffic-pool.service'
        require     => [Systemd::Unit['traffic-pool.service'],File[$varlib_path]]
    }

    nrpe::monitor_systemd_unit_state { 'traffic-pool':
        require  => Systemd::Unit['traffic-pool.service'],
        critical => false, # promote to true once better-tested in the real world
    }

}
