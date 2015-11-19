# To be included by all concrete 1layer cache roles
class role::cache::1layer {
    include role::cache::base

    if $::role::cache::configuration::has_ganglia {
        include varnish::monitoring::ganglia
    }
}
