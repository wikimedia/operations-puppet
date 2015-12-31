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
    $luahandler,
    $redis_maxmemory      = '512MB',
    $ssl_settings         = undef,
    $ssl_certificate_name = false,
    $notfound_servers     = [],
    $set_xff              = false,
    $redis_replication    = undef,
    $error_enabled        = false,
    $error_config         = {
        title    => 'Wikimedia Labs Error',
        logo     => '/.error/labs-logo.png',
        logo_2x  => '/.error/labs-logo-2x.png',
        logo_alt => 'Wikimedia Labs',
        favicon  => '//wikitech.wikimedia.org/static/favicon/wikitech.ico',
    },
    $error_description    = 'Our servers are currently experiencing a technical problem. This is probably temporary and should be fixed soon. Please try again later.',
    $error_details        = undef,
    $banned_ips           = [],
    $banned_description   = 'You have been banned from accessing this service.',
    $web_domain           = undef,
    $blocked_user_agent_regex = 'TweetmemeBot', # T73120 - misbehaving crawler
) {
    if $ssl_certificate_name != false and $ssl_settings == undef {
        fail('ssl_certificate_nme set but ssl_settings not set')
    }

    $resolver = join($::nameservers, ' ')

    if $redis_replication and $redis_replication[$::hostname] {
        $slave_host = $redis_replication[$::hostname]
        $slaveof = "${slave_host} 6379"
    }

    redis::instance { '6379':
        settings       => {
            appendonly => 'yes',
            maxmemory  => $redis_maxmemory,
            slaveof    => $slaveof,
            dir        => '/var/lib/redis',
        },
    }

    class { 'nginx':
        variant => 'extras',
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

    file { [
        '/var/www/',
        '/var/www/error',
    ]:
        ensure => directory,
        owner  => 'www-data',
        group  => 'www-data',
        mode   => '0444',
    }

    file { '/var/www/error/labs-logo.png':
        ensure => file,
        source => 'puppet:///modules/dynamicproxy/labs-logo.png',
        owner  => 'www-data',
        group  => 'www-data',
        mode   => '0444',
    }

    file { '/var/www/error/labs-logo-2x.png':
        ensure => file,
        source => 'puppet:///modules/dynamicproxy/labs-logo-2x.png',
        owner  => 'www-data',
        group  => 'www-data',
        mode   => '0444',
    }


    file { '/var/www/error/errorpage.html':
        ensure  => file,
        content => template('dynamicproxy/errorpage.erb'),
        owner   => 'www-data',
        group   => 'www-data',
        mode    => '0444',
        require => [File['/var/www/error'],
                    File['/var/www/error/labs-logo.png'],
                    File['/var/www/error/labs-logo-2x.png']
        ],
    }

    file { '/var/www/error/banned.html':
        ensure  => file,
        content => template('dynamicproxy/banned.erb'),
        owner   => 'www-data',
        group   => 'www-data',
        mode    => '0444',
        require => [File['/var/www/error'],
                    File['/var/www/error/labs-logo.png'],
                    File['/var/www/error/labs-logo-2x.png']
        ],
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
            require => [File['/etc/nginx/lua'], Package['lua-json']],
            notify  => Service['nginx'],
        }

        file { '/etc/nginx/lua/proxymanager-v1-proxy-forwards.lua':
            ensure  => 'file',
            source  => 'puppet:///modules/dynamicproxy/proxymanager/v1/proxy-forwards.lua',
            require => [File['/etc/nginx/lua'], Package['lua-json']],
            notify  => Service['nginx'],
        }

        file { '/etc/nginx/lua/proxymanager-v1-proxy-forwards-entry.lua':
            ensure  => 'file',
            source  => 'puppet:///modules/dynamicproxy/proxymanager/v1/proxy-forwards-entry.lua',
            require => [File['/etc/nginx/lua'], Package['lua-json']],
            notify  => Service['nginx'],
        }

        package { 'lua-json':
            ensure => installed,
        }

        nginx::site { 'proxymanager':
            content => template('dynamicproxy/proxymanager.conf.erb'),
            require => [Ferm::Service['proxymanager'],
                        File['/etc/nginx/lua/list-proxy-entries.lua'],
                        File['/etc/nginx/lua/proxymanager-v1-proxy-forwards.lua'],
                        File['/etc/nginx/lua/proxymanager-v1-proxy-forwards-entry.lua']],
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

    $graphite_metric_prefix = "${labsproject}.${hostname}.reqstats"

    logster::job { 'proxy-requests':
        minute          => '*/1',
        parser          => 'LineCountLogster', # Nothing more specific yet
        logfile         => '/var/log/nginx/access.log',
        logster_options => "-o statsd --statsd-host=labmon1001.eqiad.wmnet:8125 --metric-prefix=${graphite_metric_prefix}.all",
    }

    logster::job { 'proxy-errors':
        minute          => '*/1',
        parser          => 'LineCountLogster', # Nothing more specific yet
        logfile         => '/var/log/nginx/error.log',
        logster_options => "-o statsd --statsd-host=labmon1001.eqiad.wmnet:8125 --metric-prefix=${graphite_metric_prefix}.errors",
    }
}
