# == Class: profile::memcached::instance
#
# Installs and configures a memcached instance.
#
# === Parameters
#
# [*version*]
#   There are different package versions available due to a performance test,
#   most of them are deployed/installed manually. More info: T129963
#
# [*port*]
#   Memcached TCP listening port.
#
# [*size*]
#   Memcached max memory allocated size, in megabytes.
#
# [*extended_options*]
#   Extended options to enable various memcached features.
#   Default: []
#
# [*max_seq_reqs*]
#   Maximum number of sequential requests (over the same TCP conn)
#   that memcached will process before yielding to another connection
#   (to avoid starving clients). Sets the '-R' option in memcached.
#   Default: 200 (memcached's default is 20)
#
# [*growth_factor*]
#   Slab growth factor.
#   Default: 1.25
#
# [*min_slab_size*]
#   Size of the first/smallest slab. The other slabs will be created
#   using the growth_factor parameter.
#   Default: 48
#
# [*threads*]
#   Processing threads used by memcached. Sets the '-t' option in memcached.
#   Before 1.5.x, the extensive use of locks was limiting the scalability
#   up to a maximum of 8.
#   Default: undef (memcached's default is 4)
#
class profile::memcached::instance (
    String            $version          = lookup('profile::memcached::version'),
    Stdlib::Port      $port             = lookup('profile::memcached::port'),
    Integer           $size             = lookup('profile::memcached::size'),
    Array[String]     $extended_options = lookup('profile::memcached::extended_options'),
    Integer           $max_seq_reqs     = lookup('profile::memcached::max_seq_reqs'),
    Integer           $min_slab_size    = lookup('profile::memcached::min_slab_size'),
    Float             $growth_factor    = lookup('profile::memcached::growth_factor'),
    Optional[Boolean] $enable_16        = lookup('profile::memcached::enable_16'),
    Optional[Integer] $threads          = lookup('profile::memcached::threads'),
) {
    include ::profile::prometheus::memcached_exporter

    $base_extra_options = {
        '-o' => join($extended_options, ','),
        '-D' => ':',
    }

    if $max_seq_reqs {
        $max_seq_reqs_opt = {'-R' => $max_seq_reqs}
    } else {
        $max_seq_reqs_opt = {}
    }

    if $threads {
        $threads_opt = {'-t' => $threads}
    } else {
        $threads_opt = {}
    }

    $extra_options = $base_extra_options + $max_seq_reqs_opt + $threads_opt

    class { '::memcached':
        size          => $size,
        port          => $port,
        enable_16     => $enable_16,
        version       => $version,
        growth_factor => $growth_factor,
        min_slab_size => $min_slab_size,
        extra_options => $extra_options,
    }

    ferm::service { 'memcached':
        proto  => 'tcp',
        port   => $port,
        srange => '$DOMAIN_NETWORKS',
    }
}
