# == Class profile::lvs::realserver.
# Sets up the lvs realserver IPs and the corresponding conftool-based scripts
#
# === Parameters
#
# [*pools*] Pools in the format: {$lvs_name => { services => [$svc1,$svc2,...] }
#           where the services listed are the ones that are needed to serve the lvs pool.
#           So for example if you need both apache and php7 to serve a request from a pool,
#           both should be included.
#
# [*use_conftool*] Whether to use conftool or not.
class profile::lvs::realserver(
    Hash $pools = hiera('profile::lvs::realserver::pools', {}),
    Boolean $use_conftool = hiera('profile::lvs::realserver::use_conftool'),
) {
    $present_pools = $pools.keys()
    $services = wmflib::service::fetch().filter |$lvs_name, $svc| {$lvs_name in $present_pools}
    require ::lvs::configuration
    $ips = wmflib::service::get_ips_for_services($services, $::site)

    class { '::lvs::realserver':
        realserver_ips => $ips,
    }

    if $use_conftool {
        require ::profile::conftool::client
        $pools.map |$lvs_name, $pool| {
            $pool['services']
        }.flatten().unique().each |$service| {
            # Extract all the pools in which the service is included.
            $service_pools = $pools.filter |$lvs_name, $pool| { $service in $pool['services'] }
            conftool::scripts::safe_service_restart { $service:
                lvs_pools       => keys($service_pools),
                lvs_class_hosts => $::lvs::configuration::lvs_class_hosts,
                services        => $services,
            }
        }
    }
}
