class role::docker_registry_ha::registry {
    include profile::base::production
    include profile::firewall
    include profile::nginx
    include profile::docker_registry_ha::registry
    system::role { 'docker_registry_ha':
        description => 'Docker registry HA',
    }
    include profile::lvs::realserver
}
