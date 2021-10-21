class role::docker::registry {
    include ::profile::base::production
    include ::profile::base::firewall
    include ::profile::docker::registry
}
