# Ancestor class for common resources of 1-layer clusters
class role::cache::1layer  {
    # Any changes here will affect all descendent Varnish clusters
    # unless they're overridden!
    include role::cache::base

    if $::role::cache::configuration::has_ganglia {
        include varnish::monitoring::ganglia
    }
}
