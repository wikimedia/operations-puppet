# modules/ganglia/manifests/configuration.pp

class ganglia_new::configuration {
    $clusters = hiera('ganglia_clusters')

    $url = 'http://ganglia.wikimedia.org'
    # 208.80.154.14 is neon (icinga).
    # It is not actually a gmetad host, but it should
    # be allowed to query gmond instances for use by
    # neon/icinga.
    $gmetad_hosts = [ '208.80.154.53', '208.80.154.150', '208.80.154.14' ]
    $aggregator_hosts = {
        'eqiad' => [ '208.80.154.53', '208.80.154.150' ],
        'esams' => [ '91.198.174.113' ],
        'codfw' => [ '208.80.153.4' ],
    }
    $base_port = 8649
    $id_prefix = {
        eqiad => 1000,
        codfw => 2000,
        esams => 3000,
    }
    $default_sites = ['eqiad','codfw']
}
