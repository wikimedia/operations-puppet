# modules/ganglia/manifests/configuration.pp

class ganglia::configuration {
    $clusters = hiera('ganglia_clusters')

    $url = 'http://ganglia.wikimedia.org'
    $gmetad_hosts = [ '208.80.154.53']
    $aggregator_hosts = {
        'eqiad' => [ ipresolve('install1002.wikimedia.org') ],
        'esams' => [ ipresolve('bast3002.wikimedia.org') ],
        'codfw' => [ ipresolve('install2002.wikimedia.org') ],
        'ulsfo' => [ ipresolve('bast4001.wikimedia.org') ],
    }
    $base_port = 8649
    $id_prefix = {
        eqiad => 1000,
        codfw => 2000,
        esams => 3000,
        ulsfo => 4000,
    }
    $default_sites = ['eqiad','codfw']
}
