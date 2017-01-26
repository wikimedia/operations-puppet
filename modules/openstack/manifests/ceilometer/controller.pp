# Telemetry for OpenStack - the controller
# https://wiki.openstack.org/wiki/Ceilometer
class openstack::ceilometer::controller ($novaconfig, $openstack_version=$::openstack::version) {

    include ::openstack::repo

    package { [ceilometer-api, ceilometer-collector, ceilometer-agent-central, python-ceilometerclient]:
        ensure  => present,
        require => Class['openstack::repo'];
    }

    service {'ceilometer-api':
        ensure  => running,
        require => Package['ceilometer-api'];
    }

    service {'ceilometer-collector':
        ensure  => running,
        require => Package['ceilometer-collector'];
    }

    service {'ceilometer-agent-central':
        ensure  => running,
        require => Package['ceilometer-agent-central'];
    }

    file {
        '/etc/ceilometer/ceilometer.conf':
            content => template("openstack/${openstack_version}/ceilometer/ceilometer.conf.erb"),
            owner   => 'ceilometer',
            group   => 'ceilometer',
            notify  => Service['ceilometer-api','ceilometer-collector','ceilometer-agent-central'],
            require => Package['ceilometer-api'],
            mode    => '0440';
    }
}
