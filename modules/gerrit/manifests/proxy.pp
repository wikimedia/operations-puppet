class gerrit::proxy($host        = '',
$ssl_cert    = '',
$ssl_cert_key= '') {

    $ssl_settings = ssl_ciphersuite('apache', 'compat', true)

    apache::site { 'gerrit.wikimedia.org':
        content => template('gerrit/gerrit.wikimedia.org.erb'),
    }

    # We don't use gitweb anymore, so we're going to allow spiders again
    # If it becomes a problem, just set ensure => present again
    file { '/var/www/robots.txt':
        ensure => absent,
        mode   => '0444',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/gerrit/robots-txt-disallow',
    }

    include ::apache::mod::rewrite

    include ::apache::mod::proxy

    include ::apache::mod::proxy_http

    include ::apache::mod::ssl

    include ::apache::mod::headers
}
