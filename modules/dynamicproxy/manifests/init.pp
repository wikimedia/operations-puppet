class dynamicproxy (
    $redis_maxmemory='512MB',
    $ssl_certificate_name=false,
    $notfound_servers=[],
    $luahandler='domainproxy.lua',
    $set_xff=false
) {
    class { '::redis':
        persist   => 'aof',
        dir       => '/var/lib/redis',
        maxmemory => $redis_maxmemory,
    }

    include misc::labsdebrepo

    package { 'nginx-extras':
        ensure  => latest,
        require => Class['misc::labsdebrepo'],
    }

    service { 'nginx':
        ensure  => 'running',
        require => Package['nginx-extras'],
    }

    file { '/etc/nginx/sites-available/default':
        ensure  => 'file',
        content => template('dynamicproxy/proxy.conf'),
        require => Package['nginx-extras'],
        notify  => Service['nginx'],
    }

    file { '/etc/nginx/sites-enabled/default':
        ensure  => 'link',
        target  => '/etc/nginx/sites-available/default',
        require => File['/etc/nginx/sites-available/default'],
    }

    file { '/etc/nginx/lua':
        ensure  => 'directory',
        require => Package['nginx-extras'],
    }

    file { '/etc/nginx/lua/proxy.lua':
        ensure  => 'file',
        source  => "puppet:///modules/dynamicproxy/${luahandler}",
        require => File['/etc/nginx/lua'],
        notify  => Service['nginx'],
    }

    file { '/etc/nginx/lua/resty':
        ensure  => 'directory',
        require => File['/etc/nginx/lua'],
    }

    file { '/etc/nginx/lua/resty/redis.lua':
        ensure  => 'file',
        require => File['/etc/nginx/lua/resty'],
        source  => 'puppet:///modules/dynamicproxy/redis.lua',
    }
}
