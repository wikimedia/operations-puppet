# == Class profile::lvs::realserver.
# Sets up the lvs realserver IPs and the corresponding conftool-based scripts
#
# === Parameters
#
# [*pools*] Pools in the format: {$lvs_name => { service => $svc_name, lvs_group => $group}}
#           where:
#           - lvs_name is the name of the pool referenced in lvs::configuration::service_ips
#           - svc_name is the name of the service we manage via the conftool scripts
#           - lvs_group is the subgroup (if present) of the lvs pool
#
class profile::lvs::realserver(
    Hash $pools = hiera('profile::lvs::realserver::pools'),
    Boolean $use_conftool = hiera('profile::lvs::realserver::use_conftool')
) {
    require ::lvs::configuration

    $realserver_ips = $pools.map |$lvs_name, $pool| {
        if $pool['lvs_group'] {
            $::lvs::configuration::service_ips[$lvs_name][$::site][$pool['lvs_group']]
        } else {
            $::lvs::configuration::service_ips[$lvs_name][$::site]
        }

    }
    class { '::lvs::realserver':
        realserver_ips => $realserver_ips,
    }
    if $use_conftool {
        require ::profile::conftool::client
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
