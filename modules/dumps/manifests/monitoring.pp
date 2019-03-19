class dumps::monitoring {
    Class['dumps::nfs'] -> Class['dumps::monitoring']

    nrpe::monitor_service { 'nfsd':
        ensure        => 'present',
        description   => 'nfsd cpu usage',
        nrpe_command  => '/usr/lib/nagios/plugins/check_procs -w 85 -c 95 -m CPU -C nfsd',
        contact_group => 'admins',
        retries       => 3,
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Dumps/XML-SQL_Dumps#A_dumpsdata_host_dies',
    }
}
