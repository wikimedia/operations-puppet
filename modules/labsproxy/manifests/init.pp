class labsproxy ($redis_maxmemory="512MB") {
    class { '::redis':
        persist   => "aof",
        dir       => "/var/lib/redis",
        maxmemory => $redis_maxmemory,
    }

    package { 'nginx-extras': }

    service { 'nginx':
        ensure  => 'running',
        require => Package['nginx-extras']
    }

    file { '/etc/nginx/sites-available/default':
        ensure  => 'file',
        source  => 'puppet:///modules/labsproxy/proxy.conf',
        require => Package['nginx-extras'],
        notify  => Service['nginx']
    }

    file { '/etc/nginx/lua':
        ensure  => 'directory',
        require => Package['nginx-extras']
    }

    file { '/etc/nginx/lua/proxy.lua':
        ensure  => 'file',
        source  => 'puppet:///modules/labsproxy/proxy.lua',
        require => File['/etc/nginx/lua'],
        notify  => Service['nginx']
    }

    file { '/etc/nginx/lua/resty':
        ensure  => 'directory',
        require => File['/etc/nginx/lua']
    }

    file { '/etc/nginx/lua/resty/redis.lua':
        ensure  => 'file',
        require => File['/etc/nginx/lua/resty'],
        source  => 'puppet:///modules/labsproxy/redis.lua'
    }
}
