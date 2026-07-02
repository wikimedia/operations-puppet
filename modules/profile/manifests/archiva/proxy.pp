# SPDX-License-Identifier: Apache-2.0
# Class: profile::archiva::proxy
#
# Installs a nginx proxy in front of Archiva with
# archiva.wikimedia.org's settings. The proxy will listen for HTTP
# traffic on port 80 and optionally for HTTPS traffic on port 443.
#
# Params:
#
#  [*certificate_name*]
#    Name of the TLS certificate to be used with archiva::proxy
#    (that in turn leverages Let's Encrypt/ACME). The 'ssl-cert-snakeoil' name
#    is special and forces the usage of a self signed certificate rather than
#    requesting a new one.
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
#  [*blocked_user_agents*]
#    Array of regex strings; requests whose User-Agent matches any of
#    them are rejected at nginx with 403. Joined with '|' into a single
#    case-insensitive nginx regex. Entries must be regex-safe (no
#    unescaped quotes, backslashes, or $). Default: []
#
class profile::archiva::proxy(
    String        $certificate_name    = lookup('profile::archiva::proxy::certificate_name', { 'default_value' => 'archiva' }),
    Boolean       $ssl_enabled         = lookup('profile::archiva::proxy::ssl_enabled', { 'default_value' => false }),
    Boolean       $only_localhost      = lookup('profile::archiva::proxy::only_localhost', { 'default_value' => false }),
    Boolean       $monitoring_enabled  = lookup('profile::archiva::proxy::monitoring_enabled', { 'default_value' => false }),
    Array[String] $blocked_user_agents = lookup('profile::archiva::proxy::blocked_user_agents', { 'default_value' => [] }),
){

    class { '::archiva::proxy':
        certificate_name    => $certificate_name,
        ssl_enabled         => $ssl_enabled,
        blocked_user_agents => $blocked_user_agents,
    }

    $ferm_srange = $only_localhost ? {
        true  => '(127.0.0.1 ::1)',
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
            # nginx returns 404 for '/' (only /repository/* is proxied), so the
            # probe checks for that expected response. Running over TLS (port 443)
            # also covers certificate expiry via the CertAlmostExpired alert.
            prometheus::blackbox::check::http { "${certificate_name}.wikimedia.org":
                team           => 'data-platform',
                status_matches => [404],
                probe_runbook  => 'https://wikitech.wikimedia.org/wiki/Analytics/Systems/Archiva',
            }

            #TODO remove me
            monitoring::service { 'https_archiva':
                ensure         => absent,
                description    => 'HTTPS',
                check_command  => "check_ssl_http_letsencrypt!${certificate_name}.wikimedia.org",
                notes_url      => 'https://wikitech.wikimedia.org/wiki/Analytics/Systems/Archiva',
                migration_task => 'T407117',
            }
        }
    }
}
