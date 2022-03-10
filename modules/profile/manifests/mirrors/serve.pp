class profile::mirrors::serve {

    class { '::sslcert::dhparam': }
    acme_chief::cert { 'mirrors':
        puppet_svc => 'apache2',
    }

    # Remove former nginx server, before installing apache
    package {[
      'nginx-light',
      'nginx-common',
    ]:
      ensure => absent,
    }
    Package['nginx-light'] ~> Package['apache2']

    class { '::httpd':
        modules => ['ssl', 'macro', 'headers'],
    }

    httpd::site { 'mirrors':
        content => epp(
            'profile/mirrors/mirrors.wikimedia.org.conf.epp',
            { 'ssl_settings' => ssl_ciphersuite('apache', 'strong', true) },
        ),
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
