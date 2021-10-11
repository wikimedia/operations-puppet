class openstack::cinder::service(
    $active,
    $version,
    Stdlib::Port $api_bind_port,
) {
    class { "openstack::cinder::service::${version}":
        api_bind_port           => $api_bind_port,
    }
    # config should have been declared via a profile, with proper hiera, and is
    # here only for ordering/dependency purposes:
    require "openstack::cinder::config::${version}"

    service { 'cinder-scheduler':
        ensure    => $active,
        require   => Package['cinder-scheduler'],
        subscribe => Class["openstack::cinder::config::${version}"],
    }

    service { 'cinder-api':
        ensure    => $active,
        require   => Package['cinder-api'],
        subscribe => Class["openstack::cinder::config::${version}"],
    }

    service { 'cinder-volume':
        ensure    => $active,
        require   => Package['cinder-volume'],
        subscribe => Class["openstack::cinder::config::${version}"],
    }

    rsyslog::conf { 'cinder':
        source   => 'puppet:///modules/openstack/cinder/cinder.rsyslog.conf',
        priority => 20,
    }
}
