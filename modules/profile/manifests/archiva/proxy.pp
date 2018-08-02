# Class: profile::archiva::proxy
#
# Installs a nginx proxy in front of Archiva with
# archiva.wikimedia.org's settings. The proxy will listen for HTTP
# traffic on port 80 and optionally for HTTPS traffic on port 443.
#
# Params:
#
#  [*ssl_enabled*]
#    Enable TLS settings for archiva.wikimedia.org and deploy
#    related certificates.
#
class profile::archiva::proxy(
    $ssl_enabled = hiera('profile::archiva::proxy::ssl_enabled', false),
) {

    class { '::archiva::proxy':
        ssl_enabled => $ssl_enabled,
    }

    ferm::service { 'archiva_http':
        proto => 'tcp',
        port  => 80,
    }

    if $ssl_enabled {
        ferm::service { 'archiva_https':
            proto => 'tcp',
            port  => 443,
        }

        monitoring::service { 'https_archiva':
            description   => 'HTTPS',
            check_command => 'check_ssl_http_letsencrypt!archiva.wikimedia.org',
        }
    }
}