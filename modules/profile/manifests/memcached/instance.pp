# == Class: profile::memcached::instance
#
# Installs and configures a memcached instance.
#
# === Parameters
#
# [*growth_factor*]
#   Slab growth factor.
#   Default: 1.05
#
# [*extended_options*]
#   Extended options to enable various memcached features.
#   Default: ['slab_reassign']
#
# [*version*]
#   There are different package versions available due to a performance test,
#   most of them are deployed/installed manually. More info: T129963
#   Default: 'present'
#
# [*port*]
#   Memcached TCP listening port.
#   Default: '11211'
#
# [*prometheus_nodes*]
#   Hosts allowed by the firewall to poll the memcached exporter
#   to retrieve memcached metrics.
#   Default: Value 'prometheus_nodes' defined in Hiera.
#
# [*prometheus_port*]
#   Port allowed by the firewall to publish metrics via memcached exporter.
#   Default: '11211'
#
class profile::memcached::instance (
    $growth_factor    = hiera('memcached::growth_factor', 1.05),
    $extended_options = hiera_array('memcached::extended_options', ['slab_reassign']),
    $version          = hiera('memcached::version', 'present'),
    $port             = '11211',
    $prometheus_nodes = hiera('prometheus_nodes'),
    $prometheus_port  = '9150',
) {
    $memcached_size = $::realm ? {
        'production' => 89088,
        'labs'       => 3000,
    }

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

    class { '::prometheus::memcached_exporter': }

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
