class gerrit::proxy(
    $host = $::gerrit::host,
    $domain = 'wikimedia.org',
    $slave_hosts = [],
    $slave = false,
    $maint_mode = false,
    ) {

    if $slave {
        $tls_host = "gerrit-slave.${domain}"
    } else {
        $tls_host = "gerrit.${domain}"
    }

    letsencrypt::cert::integrated { 'gerrit':
        subjects   => $tls_host,
        puppet_svc => 'apache2',
        system_svc => 'apache2',
    }

    monitoring::service { 'https':
        description   => 'HTTPS',
        check_command => "check_ssl_http_letsencrypt!${tls_host}",
        contact_group => 'admins,gerrit',
    }

    $ssl_settings = ssl_ciphersuite('apache', 'mid', true)

    apache::site { $host:
        content => template("gerrit/gerrit.${domain}.erb"),
    }

    # Error page stuff
    file { '/var/www/error.html':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('gerrit/error.html.erb'),
    }
    file { '/var/www/page-bkg.cache.jpg':
        ensure => 'link',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        target => '/var/lib/gerrit2/review_site/static/page-bkg.cache.jpg',
    }
    file { '/var/www/wikimedia-codereview-logo.cache.png':
        ensure => 'link',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => '/var/lib/gerrit2/review_site/static/wikimedia-codereview-logo.cache.png',
    }

    include ::apache::mod::rewrite

    include ::apache::mod::proxy

    include ::apache::mod::proxy_http

    include ::apache::mod::ssl

    include ::apache::mod::headers
}
