# == Class: profile::memcached::instance
#
# Installs and configures a memcached instance.
#
# === Parameters
#
# [*growth_factor*]
#   Slab growth factor.
#
# [*extended_options*]
#   Extended options to enable various memcached features.
#
# [*version*]
#   There are different package versions available due to a performance test,
#   most of them are deployed/installed manually. More info: T129963
#
# [*port*]
#   Memcached TCP listening port.
#
# [*size*]
#   Memcached max memory allocated size.
#
# [*max_seq_reqs*]
#   Maximum number of sequential requests (over the same TCP conn)
#   that memcached will process before yielding to another connection
#   (to avoid starving clients). Sets the '-R' option in memcached.
#   Default: undef (memcached's default is 20)
#
class profile::memcached::instance (
    $growth_factor    = lookup('profile::memcached::growth_factor'),
    $extended_options = lookup('profile::memcached::extended_options', {merge => unique}),
    $version          = lookup('profile::memcached::version'),
    $port             = lookup('profile::memcached::port'),
    $size             = lookup('profile::memcached::size'),
    $max_seq_reqs     = lookup('profile::memcached::max_seq_reqs', {'default_value' => 200}),
) {
    include ::profile::prometheus::memcached_exporter

    $base_extra_options = {
        '-o' => join($extended_options, ','),
        '-D' => ':',
    }

    if $max_seq_reqs {
        $extra_options = merge($base_extra_options, {'-R' => $max_seq_reqs})
    } else {
        $extra_options = $base_extra_options
    }

    class { '::memcached':
        size          => $size,
        port          => $port,
        version       => $version,
        growth_factor => $growth_factor,
        extra_options => $extra_options,
    }

    ferm::service { 'memcached':
        proto => 'tcp',
        port  => $port,
    }
}
