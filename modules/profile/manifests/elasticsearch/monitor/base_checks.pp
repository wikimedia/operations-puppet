class profile::elasticsearch::monitor::base_checks(
    Integer $shard_size_warning = hiera('profile::elasticsearch::monitor::shard_size_warning', 50),
    Integer $shard_size_critical = hiera('profile::elasticsearch::monitor::shard_size_critical', 60),
    String $threshold = hiera('profile::elasticsearch::monitor::threshold', '>=0.15'),
) {
    require ::profile::elasticsearch

    $configured_ports = $::profile::elasticsearch::filtered_instances.reduce([]) |$ports, $instance_params| {
        $ports + [$instance_params[1]['http_port']]
    }

    icinga::monitor::elasticsearch::base_checks { $::hostname:
        ports               => $configured_ports,
        shard_size_warning  => $shard_size_warning,
        shard_size_critical => $shard_size_critical,
        threshold           => $threshold,
        use_nrpe            => true,
    }
}