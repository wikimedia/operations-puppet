class mirrors::serve {
    # HTTP
    include ::nginx

    # TODO: adopt role/profile pattern and drop the lint:ignore
    include ::sslcert::dhparam # lint:ignore:wmf_styleguide
    acme_chief::cert { 'mirrors':
        puppet_svc => 'nginx',
    }
    # TODO: Monitor SSL?

    $ssl_settings = ssl_ciphersuite('nginx', 'mid', true)

    nginx::site { 'mirrors':
        content => template('mirrors/mirrors.wikimedia.org.conf.erb'),
    }

    file { '/srv/mirrors/index.html':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/mirrors/index.html',
    }

    # rsync
    include rsync::server

}
