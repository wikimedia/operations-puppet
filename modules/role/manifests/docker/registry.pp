class role::docker::registry {
    include ::profile::standard
    include ::profile::base::firewall
    include ::profile::docker::registry
}
