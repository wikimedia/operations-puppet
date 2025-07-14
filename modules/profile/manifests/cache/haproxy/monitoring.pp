# SPDX-License-Identifier: Apache-2.0
define profile::cache::haproxy::monitoring(
    Stdlib::Port $port,
    Array[Haproxy::Tlscertificate] $certificates,
) {
    # This profile depends on some resources created by profile::monitoring
    include profile::monitoring

    $certificates.each|Haproxy::Tlscertificate $cert| {
        if $cert['warning_threshold'] and $cert['critical_threshold'] {
            $check_server_name = $cert['server_names'][0]
            $check_sni_str = join($cert['server_names'], ',')
            monitoring::service { "haproxy_https_${check_server_name}_ECDSA":
                description    => "HAProxy HTTPS ${check_server_name} ECDSA",
                check_command  => "check_ssl_cdn!${cert['warning_threshold']}!${cert['critical_threshold']}!${check_server_name}!${check_sni_str}!${port}!ECDSA",
                notes_url      => 'https://wikitech.wikimedia.org/wiki/HTTPS',
                migration_task => 'T385587',
            }
        }
    }
}
