# Provides various services based off tools manifests
#
# = Parameters
#
# [*active*]
#   true if all the current set of services should run actively,
#   false if they should just be hot standby

class toollabs::services(
) inherits toollabs {

    # ugly, but this code/class (toollabs::services) is already refactored and
    # will be deleted soon anyway
    aptly::repo { 'stretch-toolsbeta':
        publish      => true,
    }

    include ::gridengine::submit_host

    diamond::collector { 'SGE':
        ensure => 'absent',
    }
}
