class labstore::monitoring::ldap(
    critical=true,
    contact_groups='wmcs-team',
    ) {

    file { '/usr/local/bin/getent_check':
        ensure => present,
        source => 'puppet:///modules/labstore/getent_check',
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
    }

    # Monitor that getent passwd over LDAP resolves in reasonable time
    # (this being the mechanism that NFS uses to fetch groups)
    nrpe::monitor_service { 'getent_check':
        critial       => $critical,
        nrpe_command  => '/usr/local/bin/getent_check',
        description   => 'Getent speed check',
        require       => File['/usr/local/bin/getent_check'],
        contact_group => $contact_groups,
    }
}
