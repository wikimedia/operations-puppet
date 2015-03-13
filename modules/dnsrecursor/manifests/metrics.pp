class dnsrecursor::metrics {
    # install ganglia metrics reporting on pdns_recursor
    file { '/usr/local/sbin/pdns_gmetric':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/dnsrecursor/pdns_gmetric',
    }
    cron { 'pdns_gmetric_cron':
        require => File['/usr/local/sbin/pdns_gmetric'],
        command => '/usr/local/sbin/pdns_gmetric',
        user    => 'root',
        minute  => '*',
    }
}
