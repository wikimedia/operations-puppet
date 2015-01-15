class dumps {
    package { 'lighttpd':
        ensure => latest,
    }

    install_certificate{ 'dumps.wikimedia.org': ca => 'RapidSSL_CA.pem' }

    file { '/etc/lighttpd/lighttpd.conf':
        mode   => '0444',
        owner  => 'root',
        group  => 'root',
        path   => '/etc/lighttpd/lighttpd.conf',
        source => 'puppet:///modules/dumps/lighttpd.conf',
    }

    service { 'lighttpd':
        ensure => running,
    }

    include vm::higher_min_free_kbytes
}
