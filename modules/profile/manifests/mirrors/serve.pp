class profile::mirrors::serve {

    class { '::sslcert::dhparam': }
    acme_chief::cert { 'mirrors':
        puppet_svc => 'nginx',
    }

    $ssl_settings = ssl_ciphersuite('nginx', 'mid', true)

    nginx::site { 'mirrors':
        content => template('profile/mirrors/mirrors.wikimedia.org.conf.erb'),
    }

    file { '/srv/mirrors/index.html':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/profile/mirrors/index.html',
    }

    class { 'rsync::server': }

    ferm::service { 'mirrors_http':
        proto => 'tcp',
        port  => '(http https)'
    }

    ferm::service { 'mirrors_rsync':
        proto => 'tcp',
        port  => '873',
    }
}
