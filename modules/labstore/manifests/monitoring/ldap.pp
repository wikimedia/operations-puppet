class labstore::monitoring::ldap {

    # Monitor that getent passwd over LDAP resolves in reasonable time
    # (this being the mechanism that NFS uses to fetch groups)
    nrpe::monitor_service { 'getent_check':
        nrpe_command => '/usr/local/bin/getent_check',
        description  => 'Getent speed check',
        require      => File['/usr/local/bin/getent_check'],
    }

    file { '/usr/local/bin/getent_check':
        ensure => present,
        source => 'puppet:///modules/labstore/getent_check',
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
    }
}
