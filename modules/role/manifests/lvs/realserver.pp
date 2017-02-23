# Class role::lvs::realserver.
# Sets up the lvs realserver IPs and the corresponding conftool-based scripts
#
# This should be a profile whenever we start creating those.
#
class role::lvs::realserver {
    require ::lvs::configuration
    # Pools in the format: $service => { lvs_name => $name}
    $lvs_pools = hiera('role::lvs::realserver::pools', {})

    # TODO: fix this when we have the future parser
    $realserver_ips_str = template('role/lvs/realserver_ips.erb')
    $realserver_ips = split($realserver_ips_str, ',')

    class { '::lvs::realserver':
        realserver_ips => $realserver_ips,
    }

    require ::profile::conftool::client

    Conftool::Scripts::Service {
        lvs_class_hosts     => $::lvs::configuration::lvs_class_hosts,
        lvs_services_config => $lvs::configuration::lvs_services,
    }

    create_resources('conftool::scripts::service', $lvs_pools)
}
