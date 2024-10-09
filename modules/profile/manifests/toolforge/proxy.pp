class profile::toolforge::proxy (
    Stdlib::Fqdn               $web_domain               = lookup('profile::toolforge::web_domain',        {default_value => 'toolforge.org'}),
    Array[Stdlib::Fqdn]        $prometheus               = lookup('prometheus_nodes',                      {default_value => ['localhost']}),
    Stdlib::Fqdn               $k8s_vip_fqdn             = lookup('profile::toolforge::k8s::apiserver_fqdn',{default_value => 'k8s.tools.eqiad1.wikimedia.cloud'}),
    Stdlib::Port               $k8s_vip_port             = lookup('profile::toolforge::k8s::ingress_port', {default_value => 30000}),
    Integer                    $rate_limit_requests      = lookup('profile::toolforge::proxy::rate_limit_requests', {default_value => 100}),
    Array[Stdlib::IP::Address] $banned_ips               = lookup('dynamicproxy::banned_ips', {default_value => []}),
    Optional[String[1]]        $blocked_user_agent_regex = lookup('dynamicproxy::blocked_user_agent_regex', {default_value => undef}),
    Optional[String[1]]        $blocked_referer_regex    = lookup('dynamicproxy::blocked_referer_regex', {default_value => undef}),
    Stdlib::Fqdn               $toolforge_api_vip_fqdn   = lookup('profile::toolforge::proxy:toolforge_api_vip_fqdn',{default_value => 'api.svc.tools.eqiad1.wikimedia.cloud'}),
    Stdlib::Port               $toolforge_api_vip_port   = lookup('profile::toolforge::proxy:toolforge_api_vip_port',{default_value => 30003}),
) {
    $acme_certname = 'toolforge'
    acme_chief::cert { $acme_certname:
        puppet_rsc => Exec['nginx-reload'],
    }
    class { '::sslcert::dhparam': } # deploys /etc/ssl/dhparam.pem, required by nginx

    $resolver = $::nameservers.join(' ')

    file { '/etc/nginx/nginx.conf':
        ensure  => file,
        content => template('profile/toolforge/proxy/nginx.conf.erb'),
        require => Package['nginx-common'],
        notify  => Service['nginx'],
    }

    file { '/etc/security/limits.conf':
        ensure  => file,
        source  => 'puppet:///modules/profile/toolforge/proxy/limits.conf',
        require => Package['nginx-common'],
        notify  => Service['nginx'],
    }

    class { '::nginx':
        variant => 'extras',
    }

    $ssl_settings = ssl_ciphersuite('nginx', 'compat')
    nginx::site { 'proxy':
        content => template('profile/toolforge/proxy/nginx-site.conf.erb'),
    }
    nginx::site { 'toolforge-api':
        content => epp('profile/toolforge/proxy/toolforge-api.epp',
            {
                toolforge_api_vip_fqdn => $toolforge_api_vip_fqdn,
                toolforge_api_vip_port => $toolforge_api_vip_port,
                banned_ips             => $banned_ips,
                acme_certname          => $acme_certname,
                resolver               => $resolver,
                rate_limit_requests    => $rate_limit_requests,
                ssl_settings           => $ssl_settings,
                web_domain             => $web_domain,
            }
        ),
    }

    logrotate::conf { 'nginx':
        ensure => present,
        source => 'puppet:///modules/profile/toolforge/proxy/logrotate',
    }

    systemd::timer::job { 'dynamicproxy_logrotate':
        ensure      => present,
        description => 'Logrotation for Toolforge front proxy',
        user        => 'root',
        command     => '/usr/sbin/logrotate /etc/logrotate.conf',
        interval    => {'start' => 'OnCalendar', 'interval' => '*-*-* 00/1:00:00'}
    }

    if debian::codename::eq('buster') {
        redis::instance { '6379':
            ensure => absent,
        }

        prometheus::redis_exporter { '6379':
            ensure => absent,
        }

        file { '/usr/local/sbin/proxylistener':
            ensure => absent,
        }

        systemd::service { 'proxylistener':
            ensure  => absent,
            content => '',
        }

        file { '/etc/nginx/lua':
            ensure  => absent,
            recurse => true,
            purge   => true,
            force   => true,
        }
    }

    file { [
        '/var/www/',
        '/var/www/error',
    ]:
        ensure  => directory,
        owner   => 'www-data',
        group   => 'www-data',
        mode    => '0444',
        recurse => true,
        purge   => true,
        force   => true,
    }

    file { '/var/www/error/favicon.ico':
        ensure  => file,
        source  => 'puppet:///modules/profile/toolforge/proxy/favicon.ico',
        require => File['/var/www/error'],
    }

    file { '/var/www/error/toolforge-logo.png':
        ensure  => file,
        source  => 'puppet:///modules/profile/toolforge/proxy/toolforge-logo.png',
        require => [File['/var/www/error']],
    }

    file { '/var/www/error/toolforge-logo-2x.png':
        ensure  => file,
        source  => 'puppet:///modules/profile/toolforge/proxy/toolforge-logo-2x.png',
        require => [File['/var/www/error']],
    }

    file { '/var/www/error/robots.txt':
        ensure => file,
        source => 'puppet:///modules/profile/toolforge/proxy/robots.txt',
        owner  => 'www-data',
        group  => 'www-data',
        mode   => '0444',
    }

    mediawiki::errorpage {
        default:
            favicon     => '/.error/favicon.ico',
            pagetitle   => 'Wikimedia Toolforge Error',
            logo_src    => '/.error/toolforge-logo.png',
            logo_srcset => '/.error/toolforge-logo-2x.png 2x',
            logo_width  => 120,
            logo_height => 120,
            logo_alt    => 'Wikimedia Toolforge',
            logo_link   => 'https://wikitech.wikimedia.org/wiki/Portal:Toolforge',
            footer      => "<p>${::facts['networking']['fqdn']}</p>",
            owner       => 'www-data',
            group       => 'www-data',
            mode        => '0444';

        '/var/www/error/errorpage.html':
            content => '<p>Our servers are currently experiencing a technical problem. This is probably temporary and should be fixed soon. Please try again later.</p>';
        '/var/www/error/banned.html':
            content => '<p>You have been banned from accessing Toolforge. Please see <a href="https://wikitech.wikimedia.org/wiki/Help:Toolforge/Banned">Help:Toolforge/Banned</a> for more information on why and on how to resolve this.</p>';
        '/var/www/error/ratelimit.html':
            content => '<p>You are trying to access this service too fast.</p>';
    }

    ensure_packages('goaccess')  # webserver statistics, T121233

    ferm::service{ 'http':
        proto => 'tcp',
        port  => '80',
        desc  => 'HTTP webserver for the entire world',
    }

    ferm::service { 'https':
        proto => 'tcp',
        port  => '443',
        desc  => 'HTTPS webserver for the entire world',
    }

    # prometheus nginx metrics
    class { 'prometheus::nginx_exporter': }

    $prometheus_hosts = join($prometheus, ' ')
    ferm::service { 'prometheus_nginx_exporter':
        proto  => 'tcp',
        port   => '9113', # this is the default
        desc   => 'prometheus nginx exporter',
        srange => "@resolve((${prometheus_hosts}))",
    }

    prometheus::blackbox::check::http { $web_domain:
        path                => '/.well-known/healthz',
        ip_families         => ['ip4'],
        prometheus_instance => 'tools',
        team                => 'wmcs',
        severity            => 'warning',
    }
}
