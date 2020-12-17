class profile::elasticsearch::monitor::base_checks(
    Integer $shard_size_warning = lookup('profile::elasticsearch::monitor::shard_size_warning', {'default_value' => 110}),
    Integer $shard_size_critical = lookup('profile::elasticsearch::monitor::shard_size_critical', {'default_value' => 140}),
    String $threshold = lookup('profile::elasticsearch::monitor::threshold', {'default_value' => '>=0.15'}),
    Integer $timeout = lookup('profile::elasticsearch::monitor::timeout', {'default_value' => 4}),
) {
    require ::profile::elasticsearch

    $configured_ports = $::profile::elasticsearch::filtered_instances.reduce([]) |$ports, $instance_params| {
        $ports + [$instance_params[1]['http_port']]
    }

    # For monitoring of eqiad/codfw cirrus clusters, see icinga::monitor::elasticsearch::cirrus_cluster_checks
    icinga::monitor::elasticsearch::base_checks { $::hostname:
        ports               => $configured_ports,
        shard_size_warning  => $shard_size_warning,
        shard_size_critical => $shard_size_critical,
        timeout             => $timeout,
        threshold           => $threshold,
        use_nrpe            => true,
    }
}
