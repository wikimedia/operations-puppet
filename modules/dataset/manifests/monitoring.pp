class dataset::monitoring {
    Class['dataset::nfs'] -> Class['dataset::monitoring']

    file { 'check_nfsd':
        path   => '/usr/lib/nagios/plugins/check_nfsd',
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/dataset/check_nfsd',
    }

    nrpe::monitor_service { 'nfsd':
        ensure        => 'present',
        description   => 'nfsd cpu usage',
        nrpe_command  => '/usr/lib/nagios/plugins/check_nfsd',
        contact_group => 'admins',
        retries       => 10,
    }
}
