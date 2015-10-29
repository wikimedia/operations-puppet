define ganglia::monitor::aggregator::instance($monitored_site) {
    Ganglia::Monitor::Aggregator::Instance[$title] ->
    Service['ganglia-monitor-aggregator']

    include ganglia::configuration
    include network::constants

    $aggregator = true

    $cluster = regsubst($title, '^(.*)_[^_]+$', '\1')
    if has_key($ganglia::configuration::clusters[$cluster], 'sites') {
        $sites = keys($ganglia::configuration::clusters[$cluster]['sites'])
    } else {
        $sites = $ganglia::configuration::default_sites
    }
    $id = $ganglia::configuration::clusters[$cluster]['id'] + $ganglia::configuration::id_prefix[$monitored_site]
    $desc = $ganglia::configuration::clusters[$cluster]['name']
    $gmond_port = $ganglia::configuration::base_port + $id
    $cname = "${desc} ${::site}"
    if $monitored_site in $sites {
        $ensure = 'present'
    } else {
        $ensure = 'absent'
    }

    # This will only be realized if base::firewall (well ferm..) is included
    ferm::rule { "aggregator-udp-${id}":
        rule => "proto udp dport ${gmond_port} { saddr \$ALL_NETWORKS ACCEPT; }",
    }
    # This will only be realized if base::firewall (well ferm..) is included
    ferm::rule { "aggregator-tcp-${id}":
        rule => "proto tcp dport ${gmond_port} { saddr \$ALL_NETWORKS ACCEPT; }",
    }

    # Run these instances in the foreground
    $daemonize = 'no'

    file { "/etc/ganglia/aggregators/${id}.conf":
        ensure  => $ensure,
        require => File['/etc/ganglia/aggregators'],
        mode    => '0444',
        content => template("${module_name}/gmond.conf.erb"),
        notify  => Service['ganglia-monitor-aggregator'],
    }
}
