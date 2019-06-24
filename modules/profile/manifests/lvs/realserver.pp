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
    require ::lvs::configuration

    # Extract all the realserver IPs from the lvs_configuration
    $realserver_ips_raw = $pools.map |$lvs_name, $pool| {
        $ips = $::lvs::configuration::lvs_services[$lvs_name]['ip']
        if !($::site in $ips) {
            undef
        }
        elsif $ips[$::site] =~ String {
            $ips[$::site]
        }
        else {
            $ips[$::site].map |$lbl, $ip| {
                $ip
            }
        }
    }
    $realserver_ips = unique(flatten($realserver_ips_raw).filter |$ip| { $ip != undef})
    class { '::lvs::realserver':
        realserver_ips => $realserver_ips,
    }

    if $use_conftool {
        require ::profile::conftool::client
        $all_services = $pools.map |$lvs_name, $pool| {
            $pool['services']
        }
        unique(flatten($all_services)).each |$service| {
            # Extract all the pools in which the service is included.
            $service_pools = $pools.filter |$lvs_name, $pool| { $service in $pool['services'] }
            conftool::scripts::safe_service_restart { $service:
                lvs_pools       => keys($service_pools),
                lvs_class_hosts => $::lvs::configuration::lvs_class_hosts,
                lvs_services    => $::lvs::configuration::lvs_services
            }
            # Remove the old-style restart script, temporary
            file { "/usr/local/bin/restart-${service}":
                ensure => absent,
            }
        }
    }
}
