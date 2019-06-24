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
define conftool::scripts::safe_service_restart(
    Array[String] $lvs_pools,
    Hash $lvs_services,
    Hash $lvs_class_hosts,
) {
    file { "/usr/local/sbin/restart-${title}":
        ensure  => present,
        content => template('conftool/safe-restart.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
    }
}
