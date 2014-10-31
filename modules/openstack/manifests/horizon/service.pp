class openstack::horizon::service($openstack_version="havana", $novaconfig) {

    # basic horizon packages and config
    if ! defined(Class["openstack::repo"]) {
        class { "openstack::repo": openstack_version => $openstack_version }
    }

    package { [ "openstack-dashboard" ]:
        ensure  => present,
        require => Class["openstack::repo"];
    }

    file {
        "/etc/openstack-dashboard/local_settings.py":
            content => template("openstack/${$openstack_version}/horizon/local_settings.py.erb"),
            owner   => 'horizon',
            group   => 'horizon',
            notify  => Service['apache2'],
            require => Package['openstack-dashboard'],
            mode    => '0440';
    }

    # web services to host horizon
    if !defined(Class["webserver::php5"]) {
        class {'webserver::php5': ssl => true; }
    }

    include apache::mod::wsgi

    if !defined(Class["memcached"]) {
        class { "memcached":
            memcached_ip => "127.0.0.1",
            pin          => true;
        }
    }

    # This is installed by the openstack-dashboard package, but we don't want it;
    #  it interferes with our managed 'horizon.conf'
    file {'/etc/apache2/conf.d/openstack-dashboard.conf':
        ensure => absent;
    }

    apache::conf { 'horizon':
        content => template("openstack/${$openstack_version}/horizon/openstack-dashboard.conf.erb"),
    }
}
