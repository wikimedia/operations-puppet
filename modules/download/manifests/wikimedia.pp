class download::wikimedia($nginx=false) {
    system::role { 'download::wikimedia':
        description => 'download.wikimedia.org' }

    install_certificate{ 'dumps.wikimedia.org': ca => 'RapidSSL_CA.pem' }
    include generic::higher_min_free_kbytes

    if ($nginx) {
        if ($::lsbdistcodename == 'lucid') {
            package { 'nginx':
                ensure => latest,
            }
        }
        else {
            package { 'nginx-full':
                ensure => latest,
            }
        }

        file { '/etc/nginx/nginx.conf':
            mode    => '0444',
            owner   => 'root',
            group   => 'root',
            path    => '/etc/nginx/nginx.conf',
            content => template('download/nginx/nginx.conf.erb'),
        }

        file { '/etc/nginx/sites-available/dumps.conf':
            mode   => '0444',
            owner  => 'root',
            group  => 'root',
            path   => '/etc/nginx/sites-available/dumps.conf',
            source => 'puppet:///modules/download/nginx/dumps.conf',
        }

        service { 'nginx':
            ensure => running,
        }

        monitor_service { 'nginx http':
            description   => 'nginxHTTP',
            check_command => 'check_http'
        }
    }
    else {
        package { 'lighttpd':
            ensure => latest,
        }

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

        monitor_service { 'lighttpd http':
            description   => 'LighttpdHTTP',
            check_command => 'check_http'
        }
    }
}
