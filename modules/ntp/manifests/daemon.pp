define ntp::daemon($servers=[], $peers=[], $query_acl=[], $time_acl=[], $servers_opt='', $ensure='present') {
    package { 'ntp': ensure => latest }

    file { 'ntp.conf':
        mode    => '0644',
        owner   => root,
        group   => root,
        path    => '/etc/ntp.conf',
        content => template('ntp/ntp-conf.erb'),
    }

    service { 'ntp':
        ensure    => ensure_service($ensure),
        require   => [ File['ntp.conf'], Package['ntp'] ],
        subscribe => File['ntp.conf'],
    }
}
