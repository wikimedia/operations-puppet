class profile::toolforge::proxy (
    Stdlib::Fqdn               $web_domain               = lookup('profile::toolforge::web_domain',        {default_value => 'toolforge.org'}),
    Stdlib::Fqdn               $static_domain            = lookup('profile::toolforge::static::static_domain', {default_value => 'tools-static.wmflabs.org'}),
    Stdlib::Fqdn               $k8s_vip_fqdn             = lookup('profile::toolforge::k8s::apiserver_fqdn',{default_value => 'k8s.tools.eqiad1.wikimedia.cloud'}),
    Integer                    $rate_limit_requests      = lookup('profile::toolforge::proxy::rate_limit_requests', {default_value => 100}),
    Array[Stdlib::IP::Address] $banned_ips               = lookup('dynamicproxy::banned_ips', {default_value => []}),
) {
    $acme_certname = 'toolforge'
    acme_chief::cert { $acme_certname:
        puppet_rsc => Exec['nginx-reload'],
    }
    class { '::sslcert::dhparam': } # deploys /etc/ssl/dhparam.pem, required by nginx

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

    file { [
        '/var/www/error/favicon.ico',
        '/var/www/error/robots.txt',
        '/var/www/error/toolforge-logo.png',
        '/var/www/error/toolforge-logo-2x.png',
    ]:
        ensure => absent,
    }

    mediawiki::errorpage {
        default:
            favicon     => "https://${static_domain}/admin/errors/favicon.ico",
            pagetitle   => 'Wikimedia Toolforge Error',
            logo_src    => "https://${static_domain}/admin/errors/toolforge-logo.png",
            logo_srcset => "https://${static_domain}/admin/errors/toolforge-logo-2x.png 2x",
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

    file { '/etc/logrotate.d/nginx-postrotate':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }
    file { '/etc/logrotate.d/nginx-postrotate/toolviews':
        ensure => file,
        source => 'puppet:///modules/profile/toolforge/proxy/toolviews-nginx.sh',
        owner  => 'root',
        group  => 'root',
        mode   => '0544',
    }

    # prometheus nginx metrics
    class { 'prometheus::nginx_exporter': }

    prometheus::blackbox::check::http { $web_domain:
        path                => '/.well-known/healthz',
        prometheus_instance => 'tools',
        team                => 'wmcs',
        severity            => 'warning',
    }
}
