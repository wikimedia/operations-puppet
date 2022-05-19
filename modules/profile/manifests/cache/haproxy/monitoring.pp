define profile::cache::haproxy::monitoring(
    Stdlib::Port $port,
    Array[Haproxy::Tlscertificate] $certificates,
    Boolean $do_ocsp,
    Boolean $acme_chief,
) {
    # This profile depends on some resources created by profile::monitoring
    include profile::monitoring

    if $do_ocsp {
        $https_check = 'check_ssl_ats_ocsp'
    } else {
        $https_check = 'check_ssl_ats'
    }
    $certificates.each|Haproxy::Tlscertificate $cert| {
        if $cert['warning_threshold'] and $cert['critical_threshold'] {
            $check_server_name = $cert['server_names'][0]
            $check_sni_str = join($cert['server_names'], ',')
            ['ECDSA', 'RSA'].each |String $algorithm| {
                monitoring::service { "haproxy_https_${check_server_name}_${algorithm}":
                    description   => "HAProxy HTTPS ${check_server_name} ${algorithm}",
                    check_command => "${https_check}!${cert['warning_threshold']}!${cert['critical_threshold']}!${check_server_name}!${check_sni_str}!${port}!${algorithm}",
                    notes_url     => 'https://wikitech.wikimedia.org/wiki/HTTPS',
                }
            }
        }
    }

    if $do_ocsp {
        $check_args = '-c 259500 -w 173100 -d /var/cache/ocsp -g "*.ocsp"'
        $check_args_acme_chief = '-c 518400 -w 432000 -d /etc/acmecerts -g "*/live/*.ocsp"'
        nrpe::monitor_service { 'haproxy_ocsp_freshness':
            description  => 'Freshness of OCSP Stapling files (HAProxy)',
            nrpe_command => "/usr/local/lib/nagios/plugins/check_fresh_files_in_dir ${check_args}",
            notes_url    => 'https://wikitech.wikimedia.org/wiki/HTTPS/Unified_Certificates',
        }
        nrpe::monitor_service { 'haproxy_ocsp_freshness_acme_chief':
            ensure       => bool2str($acme_chief, 'present', 'absent'),
            description  => 'Freshness of OCSP Stapling files (HAProxy acme-chief)',
            nrpe_command => "/usr/local/lib/nagios/plugins/check_fresh_files_in_dir ${check_args_acme_chief}",
            notes_url    => 'https://wikitech.wikimedia.org/wiki/HTTPS/Unified_Certificates',
        }
    }
}
