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
#  [*only_localhost*]
#    Right after the installation step, achiva will ask to the user
#    to create an Admin account with related password. If the host is exposed
#    to untrusted networks (like the public Internet), it will have no
#    protection against any attacker. This option restricts the firewall rules
#    to allow only localhost TCP connections.
#
#  [*monitoring_enabled*]
#    Enable monitoring/alarming.
#    Default: false
#
class profile::archiva::proxy(
    $ssl_enabled        = hiera('profile::archiva::proxy::ssl_enabled', false),
    $only_localhost     = hiera('profile::archiva::proxy::only_localhost', false),
    $monitoring_enabled = hiera('profile::archiva::proxy::monitoring_enabled', false),
) {

    class { '::archiva::proxy':
        ssl_enabled => $ssl_enabled,
    }

    $ferm_srange = $only_localhost ? {
        true  => '(127.0.0.1 localhost)',
        false => undef,
    }

    ferm::service { 'archiva_http':
        proto  => 'tcp',
        port   => 80,
        srange => $ferm_srange,
    }

    if $ssl_enabled {
        ferm::service { 'archiva_https':
            proto  => 'tcp',
            port   => 443,
            srange => $ferm_srange,
        }

        if $monitoring_enabled {
            monitoring::service { 'https_archiva':
                description   => 'HTTPS',
                check_command => 'check_ssl_http_letsencrypt!archiva.wikimedia.org',
            }
        }
    }
}