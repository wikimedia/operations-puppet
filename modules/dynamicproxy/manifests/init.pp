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
        title       => 'Wikimedia Labs Error',
        logo        => '/.error/labs-logo.png',
        logo_2x     => '/.error/labs-logo-2x.png',
        logo_width  => '135',
        logo_height => '157',
        logo_alt    => 'Wikimedia Labs',
        favicon     => 'https://wikitech.wikimedia.org/static/favicon/wikitech.ico',
    },
    $error_description    = 'Our servers are currently experiencing a technical problem. This is probably temporary and should be fixed soon. Please try again later.',
    $error_details        = undef,
    $banned_ips           = [],
    $banned_description   = 'You have been banned from accessing this service.',
    $web_domain           = undef,
    $blocked_user_agent_regex = 'TweetmemeBot', # T73120 - misbehaving crawler
    $https_upgrade        = false,
) {
    if $ssl_certificate_name != false and $ssl_settings == undef {
        fail('ssl_certificate_name set but ssl_settings not set')
    }

    $resolver = join($::nameservers, ' ')

    $redis_port = '6379'
    if $redis_replication and $redis_replication[$::hostname] {
        $slave_host = $redis_replication[$::hostname]
        $slaveof = "${slave_host} ${redis_port}"
    }

    redis::instance { $redis_port:
        settings => {
            # Protected by iptables  / ferm rules from elsewhere
            # We need to allow this so we can replicate
            bind           => '0.0.0.0',
            appendonly     => 'yes',
            appendfilename => "${::hostname}-${redis_port}.aof",
            maxmemory      => $redis_maxmemory,
            slaveof        => $slaveof,
            dir            => '/var/lib/redis',
        },
    }

    class { '::nginx':
        variant => 'extras',
    }

    # For logrotate to work on both timing and size, it must run hourly
    logrotate::conf { 'nginx':
        ensure => present,
        source => 'puppet:///modules/dynamicproxy/logrotate',
    }

    file { '/etc/cron.daily/logrotate':
        ensure => absent,
    }

    file {'/etc/cron.hourly/logrotate':
        ensure => file,
        source => 'puppet:///modules/dynamicproxy/logrotate.cron',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
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

    mediawiki::errorpage { '/var/www/error/errorpage.html':
        favicon     => $error_config['favicon'],
        pagetitle   => $error_config['title'],
        logo_src    => $error_config['logo'],
        logo_srcset => "${error_config['logo_2x']} 2x",
        logo_width  => $error_config['logo_width'],
        logo_height => $error_config['logo_height'],
        logo_alt    => $error_config['logo_alt'],
        content     => "<p>${error_description}</p>",
        footer      => $error_details,
        owner       => 'www-data',
        group       => 'www-data',
        mode        => '0444',
        require     => [File['/var/www/error'],
                        File['/var/www/error/labs-logo.png'],
                        File['/var/www/error/labs-logo-2x.png']
        ],
    }

    mediawiki::errorpage { '/var/www/error/banned.html':
        favicon     => $error_config['favicon'],
        pagetitle   => $error_config['title'],
        logo_src    => $error_config['logo'],
        logo_srcset => "${error_config['logo_2x']} 2x",
        logo_alt    => $error_config['logo_alt'],
        logo_width  => $error_config['logo_width'],
        logo_height => $error_config['logo_height'],
        content     => "<p>${banned_description}</p>",
        owner       => 'www-data',
        group       => 'www-data',
        mode        => '0444',
        require     => [File['/var/www/error'],
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

        package { 'lua-json':
            ensure => installed,
        }

        nginx::site { 'proxymanager':
            content => template('dynamicproxy/proxymanager.conf.erb'),
            require => File['/etc/nginx/lua/list-proxy-entries.lua'],
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

    # T209709
    nginx::status_site { 'diamond-monitor-proxy': }

    # Also monitor local redis
    include ::redis::client::python
}
