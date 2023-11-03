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
    Array[String]                    $ssl_settings,
    Hash[String, Dynamicproxy::Zone] $supported_zones,
    Optional[Stdlib::Fqdn]           $redis_primary,
    Array[Stdlib::IP::Address]       $banned_ips,
    String                           $blocked_user_agent_regex,
    String                           $blocked_referer_regex,
    Array[Stdlib::Fqdn]              $xff_fqdns,
    Integer                          $rate_limit_requests,
    String[1]                        $redis_maxmemory = '512MB',
    Array[Stdlib::IP::Address]       $nameservers = [],
) {
    $acme_certs = $supported_zones.values.map |Dynamicproxy::Zone $zone| { $zone['acmechief_cert'] }.unique

    acme_chief::cert { $acme_certs:
        puppet_rsc => Exec['nginx-reload'],
    }

    $resolver = $nameservers.join(' ')

    $redis_port = '6379'
    if $redis_primary and !($redis_primary in [$::facts['hostname'], $::facts['fqdn']]) {
        $slaveof = "${redis_primary} ${redis_port}"
    } else {
        $slaveof = undef
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

    # Monitoring!
    prometheus::redis_exporter { '6379': }

    class { '::nginx':
        variant => 'extras',
    }

    logrotate::conf { 'nginx':
        ensure => present,
        source => 'puppet:///modules/dynamicproxy/logrotate',
    }

    systemd::timer::job { 'dynamicproxy_logrotate':
        ensure      => present,
        description => 'Logrotation for Dynamic Proxy',
        user        => 'root',
        command     => '/usr/sbin/logrotate /etc/logrotate.conf',
        interval    => {'start' => 'OnCalendar', 'interval' => '*-*-* 00/1:00:00'}
    }

    file { '/etc/nginx/nginx.conf':
        ensure  => file,
        content => template('dynamicproxy/nginx.conf.erb'),
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

    file { '/var/www/error/wmcs-logo.png':
        ensure => file,
        source => 'puppet:///modules/dynamicproxy/wmcs-logo.png',
        owner  => 'www-data',
        group  => 'www-data',
        mode   => '0444',
    }

    file { '/var/www/error/wmcs-logo-2x.png':
        ensure => file,
        source => 'puppet:///modules/dynamicproxy/wmcs-logo-2x.png',
        owner  => 'www-data',
        group  => 'www-data',
        mode   => '0444',
    }

    mediawiki::errorpage {
        default:
            favicon     => 'https://wikitech.wikimedia.org/static/favicon/wikitech.ico',
            logo_src    => '/.error/wmcs-logo.png',
            logo_srcset => '/.error/wmcs-logo-2x.png 2x',
            logo_width  => 120,
            logo_height => 137,
            logo_alt    => 'Wikimedia Cloud Services',
            logo_link   => 'https://wikitech.wikimedia.org/wiki/Portal:Cloud_VPS',
            footer      => "<p>${::facts['networking']['fqdn']}</p>",
            owner       => 'www-data',
            group       => 'www-data',
            mode        => '0444';

        '/var/www/error/banned.html':
            doctitle  => 'Forbidden',
            pagetitle => '403 Forbidden',
            content   => '<p>You have been banned from accessing this service.</p>';
        '/var/www/error/noproxy.html':
            doctitle  => 'Not Found',
            pagetitle => '404 Not Found',
            content   => '<p>No proxy is configured for this host name. Please see <a href="https://wikitech.wikimedia.org/wiki/Help:Proxy">our documentation on Wikitech</a> for more information on configuring a proxy.</p>';
        '/var/www/error/ratelimit.html':
            doctitle  => 'Too Many Requests',
            pagetitle => '429 Too Many Requests',
            content   => '<p>You are trying to access this service too fast.</p>';
        '/var/www/error/unreachable.html':
            doctitle  => 'Error',
            pagetitle => 'Error',
            content   => '<p>This web service cannot be reached. Please contact a maintainer of this project.</p><p>Maintainers can find troubleshooting instructions from <a href="https://wikitech.wikimedia.org/wiki/Help:Proxy">our documentation on Wikitech</a>.</p>';
    }

    file { '/var/www/error/errorpage.html':
        ensure => absent,
    }

    file { '/etc/security/limits.conf':
        ensure  => file,
        source  => 'puppet:///modules/dynamicproxy/limits.conf',
        require => Package['nginx-common'],
        notify  => Service['nginx'],
    }

    $supported_zones.each |String[1] $name, Dynamicproxy::Zone $zone| {
        $fqdn = $name.regsubst('(.+)\.', '\\1')
        nginx::site { $fqdn:
            content => template('dynamicproxy/nginx-site.conf.erb'),
        }
    }

    file { '/etc/nginx/lua':
        ensure  => directory,
        require => Package['nginx-extras'],
    }

    file { '/etc/nginx/lua/domainproxy.lua':
        ensure  => file,
        source  => 'puppet:///modules/dynamicproxy/domainproxy.lua',
        require => File['/etc/nginx/lua'],
        notify  => Service['nginx'],
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
}
