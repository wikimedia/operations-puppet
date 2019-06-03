class labstore::monitoring::ldap(
    $critical=true,
    $contact_groups='wmcs-team',
    ) {

    file { '/usr/local/bin/getent_check':
        ensure => present,
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/labstore/getent_check.sh',
    }

    # Monitor that getent passwd over LDAP resolves in reasonable time
    # (this being the mechanism that NFS uses to fetch groups)
    nrpe::monitor_service { 'getent_check':
        critical      => $critical,
        nrpe_command  => '/usr/local/bin/getent_check',
        description   => 'Getent speed check',
        require       => File['/usr/local/bin/getent_check'],
        contact_group => $contact_groups,
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Portal:Data_Services/Admin/Labstore',
    }
}
