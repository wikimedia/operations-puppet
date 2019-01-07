class role::docker_registry_ha::registry {
    include ::standard
    include ::profile::base::firewall
    include ::profile::docker_registry_ha::registry
    system::role { 'docker_registry_ha':
        description => 'Docker registry HA',
    }
}
