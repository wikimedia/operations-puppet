class role::docker_registry_ha::registry {
    include profile::base::production
    include profile::firewall
    include profile::nginx
    include profile::docker_registry_ha::registry
    include profile::lvs::realserver
}
