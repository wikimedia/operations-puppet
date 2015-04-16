# Ancestor class for common resources of 1-layer clusters
class role::cache::1layer {
    include role::cache::base

    # Any changes here will affect all descendent Varnish clusters
    # unless they're overridden!

    if $::role::cache::configuration::has_ganglia {
        include varnish::monitoring::ganglia
    }
}
