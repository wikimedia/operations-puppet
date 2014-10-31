class openstack::horizon::service($openstack_version='havana', $novaconfig) {

    # basic horizon packages and config
    if ! defined(Class['openstack::repo']) {
        class { 'openstack::repo': openstack_version => $openstack_version }
    }

    package { [ 'openstack-dashboard' ]:
        ensure  => present,
        require => Class['openstack::repo', 'webserver::php5', 'apache::mod::wsgi'];
    }

    # web services to host horizon
    if !defined(Class['webserver::php5']) {
        class {'webserver::php5': ssl => true; }
    }

    include apache::mod::wsgi

    if !defined(Class['memcached']) {
        class { 'memcached':
            memcached_ip => '127.0.0.1',
            pin          => true;
        }
    }

    # This is installed by the openstack-dashboard package,
    #  it interferes with our managed 'horizon.conf'
    file {['/etc/apache2/conf.d/openstack-dashboard.conf',
          '/etc/apache2/conf-available/openstack-dashboard.conf',
          '/etc/apache2/conf-enabled/openstack-dashboard.conf']:
        ensure    => absent,
        require  => package['openstack-dashboard'],
    }

    file {
        '/etc/openstack-dashboard/local_settings.py':
            content => template("openstack/${$openstack_version}/horizon/local_settings.py.erb"),
            owner   => 'horizon',
            group   => 'horizon',
            notify  => Service['apache2'],
            require => File['/etc/apache2/conf.d/openstack-dashboard.conf'],
            mode    => '0440';
    }

    apache::conf { 'horizon':
        content => template("openstack/${$openstack_version}/horizon/openstack-dashboard.conf.erb"),
        require => file['/etc/openstack-dashboard/local_settings.py'],
    }
}
