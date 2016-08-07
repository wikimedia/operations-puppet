class gerrit::proxy(
    $host         = $::gerrit::host,
    $maint_mode   = false,
    $letsencrypt  = true,
    $labs_https   = true,
    ) {

    <%- if @letsencrypt -%>
    letsencrypt::cert::integrated { 'gerrit':
        subjects   => $host,
        puppet_svc => 'apache2',
        system_svc => 'apache2',
    }

    $ssl_settings = ssl_ciphersuite('apache', 'mid', true)
    <%- end -%>

    file { '/etc/apache2/gerrit-http':
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/gerrit/proxy/gerrit-http',
    }

    file { '/etc/apache2/gerrit-https':
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/gerrit/proxy/gerrit-https',
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
