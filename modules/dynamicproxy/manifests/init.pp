#Copyright 2013 Yuvi Panda <yuvipanda@gmail.com>

#Licensed under the Apache License, Version 2.0 (the "License");
#you may not use this file except in compliance with the License.
#You may obtain a copy of the License at

  #http://www.apache.org/licenses/LICENSE-2.0

#Unless required by applicable law or agreed to in writing, software
#distributed under the License is distributed on an "AS IS" BASIS,
#WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#See the License for the specific language governing permissions and
#limitations under the License.

class dynamicproxy (
    $ssl_settings,
    $resolver,
    $redis_maxmemory      = '512MB',
    $ssl_certificate_name = false,
    $notfound_servers     = [],
    $luahandler           = 'domainproxy',
    $set_xff              = false,
) {
    class { '::redis':
        persist       => 'aof',
        dir           => '/var/lib/redis',
        maxmemory     => $redis_maxmemory,
    }

    # The redis module intentionally does not restart the redis
    # service if the configuration changes, so we have to do this
    # explicitly here.
    File['/etc/redis/redis.conf'] ~> Service['redis-server']

    include misc::labsdebrepo

    class { 'nginx':
        variant => 'extras',
        require => Class['misc::labsdebrepo'],
    }

    file { '/etc/logrotate.d/nginx':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/dynamicproxy/logrotate',
    }

    file { '/etc/nginx/nginx.conf':
        ensure  => file,
        content => template('dynamicproxy/nginx.conf'),
        require => Package['nginx-common'],
        notify  => Service['nginx'],
    }

    file { '/etc/security/limits.conf':
        ensure  => file,
        source  => 'puppet:///modules/dynamicproxy/limits.conf',
        require => Package['nginx-common'],
        notify  => Service['nginx'],
    }

    nginx::site { 'proxy':
        content => template("dynamicproxy/${luahandler}.conf"),
    }

    file { '/etc/nginx/lua':
        ensure  => directory,
        require => Package['nginx-extras'],
    }

    file { "/etc/nginx/lua/${luahandler}.lua":
        ensure  => file,
        source  => "puppet:///modules/dynamicproxy/${luahandler}.lua",
        require => File['/etc/nginx/lua'],
        notify  => Service['nginx'],
    }

    if $luahandler == 'urlproxy' {
        file { '/etc/nginx/lua/list-proxy-entries.lua':
            ensure  => 'file',
            source  => 'puppet:///modules/dynamicproxy/list-proxy-entries.lua',
            require => [File['/etc/nginx/lua'], Package['liblua5.1-json']],
            notify  => Service['nginx'],
        }

        package { 'liblua5.1-json':
            ensure => installed,
        }

        nginx::site { 'proxymanager':
            content => template("dynamicproxy/proxymanager.conf.erb"),
            require => [Ferm::Service['proxymanager'],
                        File['/etc/nginx/lua/list-proxy-entries.lua']],
        }

        ferm::service { 'proxymanager':
            proto  => 'tcp',
            port   => '8081',
            desc   => 'Proxymanager service for Labs instances',
            srange => '$INTERNAL',
        }
    }

    file { '/etc/nginx/lua/resty':
        ensure  => directory,
        require => File['/etc/nginx/lua'],
    }

    file { '/etc/nginx/lua/resty/redis.lua':
        ensure  => file,
        require => File['/etc/nginx/lua/resty'],
        source  => 'puppet:///modules/dynamicproxy/redis.lua',
    }

    diamond::collector::nginx { 'diamond-monitor-proxy': }

    # Also monitor local redis
    include ::redis::client::python

    diamond::collector { 'Redis':
        require => Class['::redis::client::python'],
    }

    ferm::service{ 'http':
        proto => 'tcp',
        port  => '80',
        desc  => 'HTTP webserver for the entire world',
    }

    ferm::service{ 'https':
        proto => 'tcp',
        port  => '443',
        desc  => 'HTTPS webserver for the entire world',
    }
}
