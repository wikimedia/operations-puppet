# Class lvs::monitor_cloudelastic
#
# Monitor cloudelastic using service_checker
# This class was created to address T229621

class icinga::monitor::cloudelastic {

    # resource for the monitoring host
    monitoring::host { 'cloudelastic.wikimedia.org':
        ip_address    => '208.80.154.241',
        group         => 'lvs',
        critical      => true,
        contact_group => 'admins,team-discovery',
    }

    $services = {
        'chi'   => { 'public_port' => 8243, 'private_port' => 9243},
        'omega' => { 'public_port' => 8443, 'private_port' => 9443},
        'psi'   => { 'public_port' => 8643, 'private_port' => 9643},
    }
    $services.each |$cluster, $ports| {
        monitoring::service {
            default:
                host          => 'cloudelastic.wikimedia.org',
                group         => 'lvs',
                critical      => false,
                contact_group => 'admins,team-discovery',
                notes_url     => 'https://wikitech.wikimedia.org/wiki/Search#Administration',
            ;
            "cloudelastic_${cluster}_https":
                description   => "WMF Cloud (${cluster.capitalize} Cluster) - Prod MW AppServer Port - HTTPS",
                check_command => "check_https_lvs_on_port!cloudelastic.wikimedia.org!${ports['private_port']}!/",
            ;
            "cloudelastic_${cluster}_https_public":
                description   => "WMF Cloud (${cluster.capitalize} Cluster) - Public Internet Port - HTTPS",
                check_command => "check_https_lvs_on_port!cloudelastic.wikimedia.org!${ports['public_port']}!/",
            ;
        }
    }
}
