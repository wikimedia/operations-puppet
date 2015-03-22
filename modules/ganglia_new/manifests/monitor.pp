class ganglia_new::monitor {
    $cluster = hiera('cluster', $cluster)
    include packages
    include service
    include ganglia_new::configuration

    $id = $ganglia_new::configuration::clusters[$cluster]['id'] + $ganglia_new::configuration::id_prefix[$::site]
    $desc = $ganglia_new::configuration::clusters[$cluster]['name']
    $gmond_port = $ganglia_new::configuration::base_port + $id

    $cname = "${desc} ${::site}"
    $aggregator_hosts = $ganglia_new::configuration::aggregator_hosts[$::site]

    class { 'ganglia_new::monitor::config':
        gmond_port       => $gmond_port,
        cname            => $cname,
        aggregator_hosts => $aggregator_hosts,
    }
}
