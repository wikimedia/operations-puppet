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
    $redis_maxmemory='512MB',
    $ssl_certificate_name=false,
    $notfound_servers=[],
    $luahandler='domainproxy.lua',
    $set_xff=false,
    $resolver='10.68.16.1',
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
