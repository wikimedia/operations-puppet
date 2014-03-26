class download::wikimedia {
    system::role { 'download::wikimedia': description => 'download.wikimedia.org' }

    package { 'lighttpd':
        ensure => latest,
    }

    install_certificate{ 'dumps.wikimedia.org': ca => 'RapidSSL_CA.pem' }

    file { '/etc/lighttpd/lighttpd.conf':
        mode   => '0444',
        owner  => 'root',
        group  => 'root',
        path   => '/etc/lighttpd/lighttpd.conf',
        source => 'puppet:///modules/download/lighttpd.conf',
    }

    service { 'lighttpd':
        ensure => running,
    }

    include generic::higher_min_free_kbytes

    monitor_service { 'lighttpd http':
        description   => 'LighttpdHTTP',
        check_command => 'check_http'
    }
}
