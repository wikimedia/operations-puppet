class profile::toolforge::legacy_redirector (
    Optional[String[1]] $ssl_certificate_name = lookup('profile::toolforge::legacy_redirector::ssl_certificate_name', {default_value => 'tools-legacy'}),
) {
    $ssl_settings = ssl_ciphersuite('apache', 'compat')
    if $ssl_certificate_name {
        acme_chief::cert { $ssl_certificate_name:
            puppet_svc => 'apache2',
        }
    }

    class { 'httpd':
        modules => ['alias', 'rewrite', 'ssl'],
    }

    httpd::site { 'tools.wmflabs.org':
        content => template('profile/toolforge/legacy_redirector/tools.wmflabs.org.conf.erb'),
    }

    httpd::site { 'www.toolserver.org':
        content => template('profile/toolforge/legacy_redirector/www.toolserver.org.conf.erb'),
    }

    file { '/var/www/www.toolserver.org':
        ensure  => directory,
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        source  => 'puppet:///modules/profile/toolforge/legacy_redirector/www.toolserver.org/',
        recurse => true,
        purge   => true,
    }

    ferm::service { 'http':
        proto => 'tcp',
        port  => '80',
        desc  => 'HTTP webserver for the entire world',
    }
    ferm::service { 'https':
        proto => 'tcp',
        port  => '443',
        desc  => 'HTTPS webserver for the entire world',
    }
}
