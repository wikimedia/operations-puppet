# Telemetry for OpenStack - the agent
# https://wiki.openstack.org/wiki/Ceilometer
class openstack::ceilometer::compute ($novaconfig, $openstack_version=$::openstack::version) {

    package { [ceilometer-agent-compute]:
        ensure  => present,
    }

    service {'ceilometer-agent-compute':
        ensure  => running,
        require => Package['ceilometer-agent-compute'];
    }

    file {
        '/etc/ceilometer/ceilometer.conf':
            content => template("openstack/${openstack_version}/ceilometer/ceilometer.conf.erb"),
            owner   => 'ceilometer',
            group   => 'ceilometer',
            notify  => Service['ceilometer-agent-compute'],
            require => Package['ceilometer-agent-compute'],
            mode    => '0440';
    }
}
