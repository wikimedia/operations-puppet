class role::acme_chief::cloud {
    system::role { 'acme_chief': description => 'ACME certificate manager' }
    include ::profile::standard
    include ::profile::base::firewall
    include ::profile::acme_chief
    include ::profile::acme_chief::cloud

    if ($::labsproject in ['tools', 'toolsbeta']) {
        include ::profile::toolforge::prometheus_fixu
    }
}

