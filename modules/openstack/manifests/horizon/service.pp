class openstack::horizon::service($openstack_version='havana', $novaconfig) {

    # basic horizon packages and config
    if ! defined(Class['openstack::repo']) {
        class { 'openstack::repo': openstack_version => $openstack_version }
    }

    package { 'openstack-dashboard':
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
        }
    }

    # Blank out these files so that the (broken) dashboard
    #  package doesn't fret.
    file { ['/etc/apache2/conf-available/openstack-dashboard.conf',
            '/etc/apache2/conf-enabled/openstack-dashboard.conf']:
        ensure   => file,
        content  => '# This empty file is here to keep the openstack-dashboard package happy.',
        require  => Package['openstack-dashboard'],
    }

    file { '/etc/openstack-dashboard/local_settings.py':
        content => template("openstack/${$openstack_version}/horizon/local_settings.py.erb"),
        owner   => 'horizon',
        group   => 'horizon',
        notify  => Service['apache2'],
        require => Package['openstack-dashboard'],
        mode    => '0440',
    }

    file { ['/usr/share/openstack-dashboard/openstack_dashboard/static/dashboard/img/logo.png',
            '/usr/share/openstack-dashboard/openstack_dashboard/static/dashboard/img/logo-splash.png']:
        source  => 'puppet:///modules/openstack/horizon/216px-Wikimedia_labs_dashboard_logo.png',
        owner   => 'horizon',
        group   => 'horizon',
        require => Package['openstack-dashboard'],
        mode    => '0440',
    }

    apache::conf { 'horizon':
        content => template("openstack/${$openstack_version}/horizon/openstack-dashboard.conf.erb"),
        require => File['/etc/openstack-dashboard/local_settings.py'],
    }
}
