class certificates::base {

    include apparmor

    package { [ 'openssl', 'ssl-cert' ]:
        ensure => 'latest',
    }

    exec { 'update-ca-certificates':
        command => '/usr/sbin/update-ca-certificates',
        refreshonly => true,
    }

    package { 'ca-certificates':
        ensure => 'latest',
        notify => Exec['update-ca-certificates'],
    }

    # Server certificates now uniformly go in there
    file { '/etc/ssl/localcerts':
        ensure => directory,
        owner  => 'root',
        group  => 'ssl-cert',
        mode   => '0755',
    }

    ## NOTE: The ssl_certs abstraction for apparmor is known to exist
    ## and be mutually compatible up to Trusty; new versions will need
    ## validation before they are cleared.

    if versioncmp($::lsbdistrelease, '14.04') > 0 {
        fail("The apparmor profile for certificates::base is only known to work up to Trusty")
    }
    file { '/etc/apparmor.d/abstractions/ssl_certs':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///files/ssl/ssl_certs',
        notify => Service['apparmor'],
    }

}

