class openstack::neutron::service::rocky(
    Stdlib::Port $bind_port,
    Boolean $active,
    ) {
    # simple enough to don't require per-debian release split
    require "openstack::serverpackages::rocky::${::lsbdistcodename}"

    service {'neutron-api':
        ensure    => $active,
        require   => Package['neutron-server', 'neutron-api'],
        subscribe => [
                      File['/etc/neutron/neutron.conf'],
                      File['/etc/neutron/policy.yaml'],
                      File['/etc/neutron/plugins/ml2/ml2_conf.ini'],
            ],
    }

    package { 'neutron-server':
        ensure => 'present',
    }
    package { 'neutron-api':
        ensure => 'present',
    }

    # The rocky neutron package installs a 'neutron-api' init script
    #  rather than 'neutron-server'.  We need to override it to set the
    #  port anyway, so just remove the packaged service script and
    #  import our own instead.
    #
    # Our 'neutron-server' script is just the packaged neutron-api script
    #  renamed and with the port changed.
    file {
        '/etc/init.d/neutron-api':
            content => template('openstack/rocky/neutron/neutron-api'),
            owner   => 'root',
            group   => 'root',
            mode    => '0755',
            notify  => Service['neutron-api'],
            require => Package['neutron-server', 'neutron-api'];
        '/etc/init.d/neutron-server':
            ensure => absent;
        '/etc/neutron/neutron-api-uwsgi.ini':
            ensure  => 'present',
            owner   => 'root',
            group   => 'root',
            mode    => '0644',
            source  => 'puppet:///modules/openstack/rocky/neutron/neutron-api-uwsgi.ini',
            notify  => Service['neutron-api'],
            require => Package['neutron-api'];
        '/etc/neutron/api-paste.ini':
            ensure  => 'present',
            owner   => 'root',
            group   => 'root',
            mode    => '0644',
            source  => 'puppet:///modules/openstack/rocky/neutron/api-paste.ini',
            notify  => Service['neutron-api'],
            require => Package['neutron-api'];
        '/var/run/uwsgi/':
            ensure => directory,
            mode   => '0755';
    }
}
