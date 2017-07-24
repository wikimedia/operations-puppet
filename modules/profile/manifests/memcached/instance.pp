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
class profile::memcached::instance (
    $growth_factor    = hiera('profile::memcached::growth_factor'),
    $extended_options = hiera_array('profile::memcached::extended_options'),
    $version          = hiera('profile::memcached::version'),
    $port             = hiera('profile::memcached::port'),
    $size             = hiera('profile::memcached::size'),
) {
    include ::profile::prometheus::memcached_exporter

    class { '::memcached':
        size          => $size,
        port          => $port,
        version       => $version,
        growth_factor => $growth_factor,
        extra_options => {
            '-o' => join($extended_options, ','),
            '-D' => ':',
        }
    }

    ferm::service { 'memcached':
        proto => 'tcp',
        port  => $port,
    }
}
