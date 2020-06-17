class profile::toolforge::legacy_redirector (
    Boolean $do_https        = lookup('profile::toolforge::proxy::do_https',  {default_value => true}),
    String $canonical_domain = lookup('profile::toolforge::canonical_domain', {default_value => 'toolforge.org'}),
    String $canonical_scheme = lookup('profile::toolforge::canonical_scheme', {default_value => 'https://'}),
) {
    $resolver = join($::nameservers, ' ')

    # toolsbeta support: running without SSL as in the main front proxy
    if $do_https {
        $ssl_settings = ssl_ciphersuite('nginx', 'compat')
        # SSL certificate for tools.wmflabs.org
        $ssl_certificate_name = 'tools-legacy'
        acme_chief::cert { $ssl_certificate_name:
            puppet_rsc => Exec['nginx-reload'],
        }
        class { '::sslcert::dhparam': } # deploys /etc/ssl/dhparam.pem, required by nginx
    } else {
        $ssl_certificate_name = false
    }

    class { '::nginx':
        variant => 'extras',
    }

    nginx::site { 'legacy-redirector':
        content => template('profile/toolforge/legacy-redirector.conf.erb'),
    }

    file { '/etc/nginx/lua':
        ensure  => 'directory',
        require => Package['nginx-extras'],
    }

    file { '/etc/nginx/lua/legacy_redirector.lua':
        ensure  => file,
        source  => 'puppet:///modules/profile/toolforge/legacy_redirector.lua',
        require => File['/etc/nginx/lua'],
        notify  => Service['nginx'],
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
