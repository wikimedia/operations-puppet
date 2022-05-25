class labstore::monitoring::ldap(
    Boolean $critical       = false,
    String  $contact_groups = 'wmcs-team',
){

    file { '/usr/local/bin/getent_check':
        ensure => absent,
    }

    nrpe::plugin { 'check_getent':
        source => 'puppet:///modules/labstore/getent_check.sh',
    }

    # Monitor that getent passwd over LDAP resolves in reasonable time
    # (this being the mechanism that NFS uses to fetch groups)
    nrpe::monitor_service { 'getent_check':
        critical      => $critical,
        nrpe_command  => '/usr/local/lib/nagios/plugins/check_getent',
        description   => 'Getent speed check',
        contact_group => $contact_groups,
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Portal:Data_Services/Admin/Labstore',
    }
}
