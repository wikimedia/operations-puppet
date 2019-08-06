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

    monitoring::service {
        default:
            host          => 'cloudelastic.wikimedia.org',
            group         => 'lvs',
            critical      => false,
            contact_group => 'admins,team-discovery',
            notes_url     => 'https://wikitech.wikimedia.org/wiki/Search#Administration',
        ;
        'cloudelastic_chi_https':
            description   => 'WMF Cloud (Chi Cluster) - Prod MW AppServer Port - HTTPS',
            check_command => 'check_https_lvs_on_port!cloudelastic.wikimedia.org!9243!/',
        ;
        'cloudelastic_chi_https_public':
            description   => 'WMF Cloud (Chi Cluster) - Public Internet Port - HTTPS',
            check_command => 'check_https_lvs_on_port!cloudelastic.wikimedia.org!8243!/',
        ;
        'cloudelastic_omega_https':
            description   => 'WMF Cloud (Omega Cluster) - Prod MW AppServer Port - HTTPS',
            check_command => 'check_https_lvs_on_port!cloudelastic.wikimedia.org!9443!/',
        ;
        'cloudelastic_omega_https_public':
            description   => 'WMF Cloud (Omega Cluster) - Public Internet Port - HTTPS',
            check_command => 'check_https_lvs_on_port!cloudelastic.wikimedia.org!8443!/',
        ;
        'cloudelastic_psi_https':
            description   => 'WMF Cloud (Psi Cluster) - Prod MW AppServer Port - HTTPS',
            check_command => 'check_https_lvs_on_port!cloudelastic.wikimedia.org!9643!/',
        ;
        'cloudelastic_psi_https_public':
            description   => 'WMF Cloud (Psi Cluster) - Public Internet Port - HTTPS',
            check_command => 'check_https_lvs_on_port!cloudelastic.wikimedia.org!8643!/',
        ;
    }
}
