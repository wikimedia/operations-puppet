class labsproxy ($redis_maxmemory="512MB") {
    class { '::redis':
        persist   => "aof",
        dir       => "/var/lib/redis",
        maxmemory => $redis_maxmemory,
    }

    package { 'nginx-extras': }

    file { '/etc/nginx/sites-available/default':
        ensure  => 'file',
        source  => 'puppet:///modules/labsproxy/proxy.conf',
        require => Package['nginx-extras'],
        notify  => Service['nginx']
    }

    file { '/etc/nginx/proxy.lua':
        ensure  => 'file',
        source  => 'puppet:///modules/labsproxy/proxy.lua',
        require => Package['nginx-extras'],
        notify  => Service['nginx']
    }
}
