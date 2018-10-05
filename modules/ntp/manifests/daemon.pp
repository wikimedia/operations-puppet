define ntp::daemon($servers=[], $pools=[], $peers=[], $query_acl=[], $time_acl=[], $extra_config='',
    $ensure=hiera('ntp::daemon::ensure', 'present')) {
    package { 'ntp': ensure => present }

    file { 'ntp.conf':
        mode    => '0644',
        owner   => 'root',
        group   => 'root',
        path    => '/etc/ntp.conf',
        content => template('ntp/ntp-conf.erb'),
    }

    diamond::collector { 'Ntpd': }

    service { 'ntp':
        ensure    => ensure_service($ensure),
        require   => [ File['ntp.conf'], Package['ntp'] ],
        subscribe => File['ntp.conf'],
    }
}
