class gerrit::proxy(
    $host         = $::gerrit::host,
    $maint_mode   = false,
    $gerrit_letsencrypt = true,
    ) {

    $ssl_settings = ssl_ciphersuite('apache', 'mid', true)

    if $gerrit_letsencrypt != false  {
        $ssl_cert_file = "/etc/ssl/localcerts/${host}.crt"
        $ssl_cert_chain_file = "/etc/ssl/localcerts/${host}.chain.crt"
        $ssl_cert_key_file = "/etc/ssl/private/${host}.key"
    }

    apache::site { $host:
        content => template('gerrit/gerrit.wikimedia.org.erb'),
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
