# == Class profile::lvs::realserver.
# Sets up the lvs realserver IPs and the corresponding conftool-based scripts
#
# === Parameters
#
# [*pools*] Pools in the format: {$lvs_name => { service => $svc_name, lvs_group => $group}}
#           where
#           - lvs_name is the name of the pool referenced in lvs::configuration::service_ips
#           - svc_name is the name of the service we manage via the conftool scripts
#           - lvs_group is the subgroup (if present) of the lvs pool
class profile::lvs::realserver(
    Hash $pools = hiera('profile::lvs::realserver::pools', {}),
    Boolean $use_conftool = hiera('profile::lvs::realserver::use_conftool'),
    Boolean $use_safe_restart = hiera('profile::lvs::realserver::use_safe_restart', false)
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
        # New script version
        if $use_safe_restart {
            # Extract from $pools a {service => [pool1, ...]} hash
            # that contains all the pools in which each service is included.
            $all_services = $pools.map |$lvs_name, $pool| {
                    $pool['services']
            }
            unique(flatten($all_services)).each |$service| {
                $service_pools = $pools.filter |$lvs_name, $pool| {
                    ($lvs_name == $service) or ($service in $pool)
                }
                conftool::scripts::safe_service_restart { $service:
                    lvs_pools       => keys($service_pools),
                    lvs_class_hosts => $::lvs::configuration::lvs_class_hosts,
                    lvs_services    => $::lvs::configuration::lvs_services
                }
            }
        }
        else {
            # Old-style declaration. TODO: fix this.
            $pools.each |$lvs_name, $pool| {
                $svc_name = $pool['service'] ? {
                    undef   => $lvs_name,
                    default => $pool['service']
                }

                conftool::scripts::service {$svc_name:
                    lvs_name            => $lvs_name,
                    lvs_class_hosts     => $::lvs::configuration::lvs_class_hosts,
                    lvs_services_config => $lvs::configuration::lvs_services,
                }
            }
        }
    }

}
