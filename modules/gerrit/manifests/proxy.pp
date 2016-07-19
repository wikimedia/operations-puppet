class gerrit::proxy(
    $host         = $::gerrit::host,
    $lets_encrypt = true,
    $maint_mode   = false,
    ) {

    $ssl_settings = ssl_ciphersuite('apache', 'compat', true)

    if $lets_encrypt {
        $ssl_cert_file = '/etc/acme/cert/gerrit.crt'
        $ssl_cert_chain_file = '/etc/acme/cert/gerrit.chain.crt'
        $ssl_cert_key_file = '/etc/acme/key/gerrit.key'
    } else {
        $ssl_cert_file = "/etc/ssl/localcerts/${host}.crt"
        $ssl_cert_chain_file = "/etc/ssl/localcerts/${host}.chain.crt"
        $ssl_cert_key_file = "/etc/ssl/private/${host}.key"
    }

    apache::site { $host:
        content => template('gerrit/gerrit.wikimedia.org.erb'),
    }

    # Error page just in case we're dying
    $ensure_maint = $maint_mode ? {
        true    => present,
        default => absent,
    }
    file { '/var/www/maintenance.html':
        ensure => $ensure_maint,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/gerrit/maintenance.html',
    }

    $ensure_link = $maint_mode ? {
        true    => 'link',
        default => absent
    }
    file { '/var/www/page-bkg.cache.jpg':
        ensure => $ensure_link,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        target => '/var/lib/gerrit2/review_site/static/page-bkg.cache.jpg',
    }

    file { '/var/www/wikimedia-codereview-logo.cache.png':
        ensure => $ensure_link,
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
