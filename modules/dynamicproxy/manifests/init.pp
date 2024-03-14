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
    Optional[Stdlib::Fqdn] $k8s_vip_fqdn = undef,
    Optional[Stdlib::Port] $k8s_vip_fqdn_port = undef,
    $luahandler,
    $redis_maxmemory          = '512MB',
    Optional[Array[String]] $ssl_settings  = undef,
    Optional[String]        $acme_certname = undef,
    $notfound_servers         = [],
    Optional[Stdlib::Fqdn] $redis_primary = undef,
    $error_enabled            = false,
    $error_config             = {
        title       => 'Wikimedia Cloud Services Error',
        logo        => '/.error/wmcs-logo.png',
        logo_2x     => '/.error/wmcs-logo-2x.png',
        logo_width  => 120,
        logo_height => 137,
        logo_alt    => 'Wikimedia Cloud Services',
        logo_link   => 'https://wikitech.wikimedia.org/wiki/Portal:Cloud_VPS',
        favicon     => 'https://wikitech.wikimedia.org/static/favicon/wikitech.ico',
    },
    $error_description        = 'Our servers are currently experiencing a technical problem. This is probably temporary and should be fixed soon. Please try again later.',
    $error_details            = undef,
    String $unreachable_description = '<p>This web service cannot be reached. Please contact a maintainer of this project.</p><p>Maintainers can find troubleshooting instructions from <a href="https://wikitech.wikimedia.org/wiki/Help:Proxy">our documentation on Wikitech</a>.</p>',
    $banned_ips               = [],
    $banned_description       = 'You have been banned from accessing this service.',
    $noproxy_description      = 'No proxy is configured for this host name.
    Please see <a href="https://wikitech.wikimedia.org/wiki/Help:Proxy">our documentation on Wikitech</a> for more information on configuring a proxy.',
    $blocked_user_agent_regex = 'TweetmemeBot', # T73120 - misbehaving crawler
    $blocked_referer_regex    = '',
    Optional[Array[Stdlib::Fqdn]] $xff_fqdns = undef,
    Integer $rate_limit_requests = 100,
) {
    # TODO: use epp templates
    #   -> that will surface some typing errors, ex. xff_fqdns = undef not being supported
    if $acme_certname and $ssl_settings == undef {
        fail('ssl_certificate_name set but ssl_settings not set')
    }

    $resolver = join($::nameservers, ' ')

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

    mediawiki::errorpage { '/var/www/error/errorpage.html':
        favicon     => $error_config['favicon'],
        pagetitle   => $error_config['title'],
        logo_src    => $error_config['logo'],
        logo_srcset => "${error_config['logo_2x']} 2x",
        logo_width  => $error_config['logo_width'],
        logo_height => $error_config['logo_height'],
        logo_alt    => $error_config['logo_alt'],
        logo_link   => $error_config['logo_link'],
        content     => "<p>${error_description}</p>",
        footer      => $error_details,
        owner       => 'www-data',
        group       => 'www-data',
        mode        => '0444',
    }

    mediawiki::errorpage { '/var/www/error/banned.html':
        favicon     => $error_config['favicon'],
        pagetitle   => $error_config['title'],
        logo_src    => $error_config['logo'],
        logo_srcset => "${error_config['logo_2x']} 2x",
        logo_width  => $error_config['logo_width'],
        logo_height => $error_config['logo_height'],
        logo_alt    => $error_config['logo_alt'],
        logo_link   => $error_config['logo_link'],
        content     => "<p>${banned_description}</p>",
        footer      => $error_details,
        owner       => 'www-data',
        group       => 'www-data',
        mode        => '0444',
    }

    mediawiki::errorpage { '/var/www/error/noproxy.html':
        favicon     => $error_config['favicon'],
        pagetitle   => $error_config['title'],
        logo_src    => $error_config['logo'],
        logo_srcset => "${error_config['logo_2x']} 2x",
        logo_width  => $error_config['logo_width'],
        logo_height => $error_config['logo_height'],
        logo_alt    => $error_config['logo_alt'],
        logo_link   => $error_config['logo_link'],
        content     => "<p>${noproxy_description}</p>",
        footer      => $error_details,
        owner       => 'www-data',
        group       => 'www-data',
        mode        => '0444',
    }

    mediawiki::errorpage { '/var/www/error/ratelimit.html':
        favicon     => $error_config['favicon'],
        pagetitle   => $error_config['title'],
        logo_src    => $error_config['logo'],
        logo_srcset => "${error_config['logo_2x']} 2x",
        logo_width  => $error_config['logo_width'],
        logo_height => $error_config['logo_height'],
        logo_alt    => $error_config['logo_alt'],
        logo_link   => $error_config['logo_link'],
        content     => '<p>You are trying to access this service too fast.</p>',
        footer      => $error_details,
        owner       => 'www-data',
        group       => 'www-data',
        mode        => '0444',
    }

    mediawiki::errorpage { '/var/www/error/unreachable.html':
        favicon     => $error_config['favicon'],
        pagetitle   => $error_config['title'],
        logo_src    => $error_config['logo'],
        logo_srcset => "${error_config['logo_2x']} 2x",
        logo_width  => $error_config['logo_width'],
        logo_height => $error_config['logo_height'],
        logo_alt    => $error_config['logo_alt'],
        logo_link   => $error_config['logo_link'],
        content     => $unreachable_description,
        footer      => $error_details,
        owner       => 'www-data',
        group       => 'www-data',
        mode        => '0444',
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
