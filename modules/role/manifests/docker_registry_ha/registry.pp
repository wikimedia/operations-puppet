class role::docker_registry_ha::registry {
    include ::profile::standard
    include ::profile::base::firewall
    include ::profile::base::firewall::log
    include ::profile::docker_registry_ha::registry
    system::role { 'docker_registry_ha':
        description => 'Docker registry HA',
    }
    include ::profile::lvs::realserver
}
