# A role to setup a HA registry
class role::docker_registry {
    include profile::base::production
    include profile::firewall
    include profile::nginx
    include profile::docker_registry
    include profile::lvs::realserver
    include profile::lvs::realserver::ipip
}
