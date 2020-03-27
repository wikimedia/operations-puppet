class profile::toolforge::legacy_redirector (
    String $canonical_domain = lookup('profile::toolforge::canonical_domain', {default_value => 'toolforge.org'}),
    String $canonical_scheme = lookup('profile::toolforge::canonical_scheme', {default_value => 'https://'}),
) {
    # SSL certificate for tools.wmflabs.org
    $ssl_cert_name = 'toolforge'
    acme_chief::cert { $ssl_cert_name:
        puppet_rsc => Exec['nginx-reload'],
    }

    class { '::nginx':
        variant => 'extras',
    }

    nginx::site { 'legacy-redirector':
        content => template('profile/toolforge/legacy-redirector.conf'),
    }

    file { '/etc/nginx/lua':
        ensure   => 'directory',
        requires => Class['Nginx'],
    }

    file { '/etc/nginx/lua/legacy_redirector.lua':
        ensure  => file,
        content => 'puppet:///modules/profile/toolforge/legacy_redirector.lua',
        notify  => Service['nginx'],
    }

    ferm::service { 'http':
        proto => 'tcp',
        port  => '80',
        desc  => 'HTTP webserver for the entire world',
    }
    ferm::service { 'https':
        proto => 'htcp',
        port  => '443',
        desc  => 'HTTPS webserver for the entire world',
    }
}
