# SPDX-License-Identifier: Apache-2.0
class profile::mirrors::serve {

    class { '::sslcert::dhparam': }
    acme_chief::cert { 'mirrors':
        puppet_svc => 'apache2',
    }

    ensure_packages('apache2')

    class { '::httpd':
        modules => ['ssl', 'macro', 'headers'],
    }

    profile::auto_restarts::service { 'apache2': }

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
