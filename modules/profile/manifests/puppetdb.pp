class profile::puppetdb(
    $master = hiera('profile::puppetdb::master'),
    $puppetmasters = hiera('puppetmaster::servers')
) {
    # The JVM heap size has been raised to 6G for T170740
    class { '::puppetmaster::puppetdb':
        master    => $master,
        heap_size => '6G',
    }

    # Only the TLS-terminating nginx proxy will be exposed
    $puppetmasters_ferm = inline_template('<%= @puppetmasters.values.flatten(1).map { |p| p[\'worker\'] }.sort.join(\' \')%>')

    ferm::service { 'puppetdb':
        proto   => 'tcp',
        port    => 443,
        notrack => true,
        srange  => "@resolve((${puppetmasters_ferm}))",
    }

    ferm::service { 'puppetdb-cumin':
        proto  => 'tcp',
        port   => 443,
        srange => '$CUMIN_MASTERS',
    }
}
