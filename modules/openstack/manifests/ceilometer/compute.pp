class openstack::ceilometer::compute ($openstack_version=$::openstack::version, $novaconfig) {

    include openstack::repo

    package { [ceilometer-agent-compute]:
        ensure  => present,
        require => Class['openstack::repo'];
    }

    service {'ceilometer-agent-compute':
        ensure  => running,
        require => Package['ceilometer-agent-compute'];
    }

    file {
        '/etc/ceilometer/ceilometer.conf':
            content => template("openstack/${openstack_version}/ceilometer/ceilometer.conf.erb"),
            owner   => ceilometer,
            group   => ceilometer,
            notify  => Service['ceilometer-agent-compute'],
            require => Package['ceilometer-agent-compute'],
            mode    => '0440';
    }
}
