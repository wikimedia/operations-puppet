# sets up a TLS proxy for Gerrit
class gerrit::proxy(
    $ipv4,
    $ipv6,
    $host         = $::gerrit::host,
    $slave_hosts  = $::gerrit::slave_hosts,
    $slave        = false,
    $maint_mode   = false,
    ) {

    if $slave {
        $tls_host = $slave_hosts[0]
    } else {
        $tls_host = $host
    }

    letsencrypt::cert::integrated { 'gerrit':
        subjects   => $tls_host,
        puppet_svc => 'apache2',
        system_svc => 'apache2',
    }

    monitoring::service { 'https':
        description   => 'HTTPS',
        check_command => "check_ssl_on_host_port_letsencrypt!${tls_host}!${tls_host}!443",
        contact_group => 'admins,gerrit',
    }

    $ssl_settings = ssl_ciphersuite('apache', 'mid', true)

    httpd::site { $tls_host:
        content => template('gerrit/apache.erb'),
    }

    # Let Apache only listen on the service IP.
    file { '/etc/apache2/ports.conf':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('gerrit/apache.ports.conf.erb'),
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
}
