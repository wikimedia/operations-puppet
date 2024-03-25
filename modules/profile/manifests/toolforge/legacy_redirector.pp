class profile::toolforge::legacy_redirector (
    Optional[String[1]] $ssl_certificate_name = lookup('profile::toolforge::legacy_redirector::ssl_certificate_name', {default_value => 'tools-legacy'}),
) {
    if debian::codename::eq('buster') {
        $ssl_settings = ssl_ciphersuite('nginx', 'compat')
        $resolver = join($::nameservers, ' ')
        if $ssl_certificate_name {
            # SSL certificate for tools.wmflabs.org
            acme_chief::cert { $ssl_certificate_name:
                puppet_rsc => Exec['nginx-reload'],
            }
            class { '::sslcert::dhparam': } # deploys /etc/ssl/dhparam.pem, required by nginx
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
    } else {
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
