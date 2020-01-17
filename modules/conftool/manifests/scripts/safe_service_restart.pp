# == define conftool::scripts::safe_service_restart
#
# Creates a safe service restart script for the titled resource.
#
# What this script will do:
# * Depool, only if pooled, the server from the $lvs_pools listed
# * Verify the load balancers have effectively depooled the server, trying repeatedly
# * Restart the service with name $title
# * Repool, only if previously pooled, the server in the pools listed
# * Verify the load balancers effectively repooled the server
#
# The advantages with respect to the older pooler-loop script we used to use is
# we allow more than one lvs pool to be depooled, and that we use conftool as a library
# so we have more control on our interaction with it.
#
# === Parameters
# [*lvs_pools*]   names of the lvs pools we want to depool
#
# [*lvs_services*] Lvs services, as defined in lvs::configuration::lvs_services
#
# [*lvs_class_hosts*] LVS hosts classes, as defined in lvs::configuration::lvs_class_hosts.
#
# If no pool is provided, or the realm is not production, the restart scripts will not use conftool
# and will just be a stub.
define conftool::scripts::safe_service_restart(
    Array[String] $lvs_pools,
    Hash $lvs_services,
    Hash $lvs_class_hosts,
) {
    # Only require the other conftool scrips if lvs pools are declared.
    if $lvs_pools != [] {
        require ::conftool::scripts
        # Find the base cli arguments shared by all scripts.
        $combined = $lvs_pools.map |$pool| {
            $service = $lvs_services[$pool]
            $port = $service['port'] ? {
                Stdlib::Port => $service['port'],
                default      => 80,
            }
            $uris = $lvs_class_hosts[$service['class']].map |$host| { "http://${host}:9090/pools/${pool}_${port}" }
            [$uris, [$service['conftool']['service']]]
        }.reduce |$stored, $current| {
            [$stored[0] + $current[0], $stored[1] + $current[1]]
        }
        if $combined {
            $uri_str = join($combined[0], ' ')
            $pool_str = join($combined[1], ' ')
            $base_cli_args = "--lvs-urls ${uri_str} --pools ${pool_str}"
        }
        # TODO: move to sbin as well. Now here for historical reasons.
        file { "/usr/local/bin/depool-${title}":
            ensure  => present,
            owner   => 'root',
            group   => 'root',
            mode    => '0555',
            content => template('conftool/safe-depool.erb')
        }

        file { "/usr/local/bin/pool-${title}":
            ensure  => present,
            owner   => 'root',
            group   => 'root',
            mode    => '0555',
            content => template('conftool/safe-pool.erb')
        }
    }
    file { "/usr/local/sbin/restart-${title}":
        ensure  => present,
        content => template('conftool/safe-restart.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
    }

}
