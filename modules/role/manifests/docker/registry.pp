class role::docker::registry {
    include ::standard
    include ::profile::base::firewall
    include ::profile::docker::registry
}
