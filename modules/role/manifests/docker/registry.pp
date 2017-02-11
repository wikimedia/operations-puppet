class role::docker::registry {
    include standard
    include ::base::firewall
    include profile::docker::registry
}
