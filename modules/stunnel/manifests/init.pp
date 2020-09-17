# @summary manage stunnle services
# @param ensure whether to ensure the class
class stunnel (
    Wmflib::Ensure   $ensure       = 'present',
    Stdlib::Unixpath $config_dir   = '/etc/stunnel',
) {
    $service_name = 'stunnel4'
    $enabled = $ensure ? {
        'present' => 1,
        default   => 0,
    }
    $client_config_dir = "${config_dir}/clients"
    $daemon_config_dir = "${config_dir}/daemons"

    $defaults = @("stunnel")
    FILES="${daemon_config_dir}/*.conf"
    OPTIONS=""
    PPP_RESTART=0
    RLIMITS=""
    ENABLED=${enabled}
    | stunnel

    ensure_packages(['stunnel4'])
    file {'/etc/default/stunnel4':
        ensure  => file,
        content => $defaults,
    }
    file {[$client_config_dir, $daemon_config_dir]:
        ensure  => directory,
        recurse => true,
        purge   => true,
    }
    service {$service_name:
        ensure  => ensure_service($ensure),
        require => [
            File['/etc/default/stunnel4'],
            Package['stunnel4'],
        ],
    }
}
