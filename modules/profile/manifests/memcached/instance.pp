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
# [*prometheus_nodes*]
#   Hosts allowed by the firewall to poll the memcached exporter
#   to retrieve memcached metrics.
#
class profile::memcached::instance (
    $growth_factor    = hiera('profile::memcached::growth_factor'),
    $extended_options = hiera_array('profile::memcached::extended_options'),
    $version          = hiera('profile::memcached::version'),
    $port             = hiera('profile::memcached::port'),
    $size             = hiera('profile::memcached::size'),
    $prometheus_nodes = hiera('prometheus_nodes')
) {
    class { '::memcached':
        size          => $memcached_size,
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

    $prometheus_port  = '9150'
    prometheus::memcached_exporter { 'default': }

    if $::realm == 'labs' {
        $ferm_srange = '$LABS_NETWORKS'
    } else {
        $prometheus_ferm_nodes = join($prometheus_nodes, ' ')
        $ferm_srange = "(@resolve((${prometheus_ferm_nodes})) @resolve((${prometheus_ferm_nodes}), AAAA))"
    }

    ferm::service { 'prometheus-memcached-exporter':
        proto  => 'tcp',
        port   => $prometheus_port,
        srange => $ferm_srange,
    }
}
