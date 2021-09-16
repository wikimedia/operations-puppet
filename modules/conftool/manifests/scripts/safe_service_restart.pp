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
# [*max_concurrency*] Maximum number of servers to restart at the same time, if poolcounter is available.
#
# If no pool is provided, or the realm is not production, the restart scripts will not use conftool
# and will just be a stub.
define conftool::scripts::safe_service_restart(
    Array[String] $lvs_pools,
    Integer $max_concurrency = 0,
) {


    # Only require the other conftool scripts if lvs pools are declared.
    if $lvs_pools != [] {
        require ::conftool::scripts

        $base_cli_args = "--pools ${lvs_pools.join(' ')}"
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
    # This file will be created independently of the presence of pools to remove or not.
    file { "/usr/local/sbin/restart-${title}":
        ensure  => present,
        content => template('conftool/safe-restart.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
    }

}
