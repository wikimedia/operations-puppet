class ganglia::monitor {
    $cluster = hiera('cluster', $cluster)
    include packages
    include service
    include ganglia::configuration

    $id = $ganglia::configuration::clusters[$cluster]['id'] + $ganglia::configuration::id_prefix[$::site]
    $desc = $ganglia::configuration::clusters[$cluster]['name']
    $gmond_port = $ganglia::configuration::base_port + $id

    $cname = "${desc} ${::site}"
    $aggregator_hosts = $ganglia::configuration::aggregator_hosts[$::site]

    class { 'ganglia::monitor::config':
        gmond_port       => $gmond_port,
        cname            => $cname,
        aggregator_hosts => $aggregator_hosts,
    }

    # export ganglia::cluster resource to expose cluster -> hosts mapping
    @@ganglia::cluster { $::fqdn:
        cluster => $cluster,
        site    => $site,
    }
}
