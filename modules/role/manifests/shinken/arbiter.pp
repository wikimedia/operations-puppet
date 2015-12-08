class role::shinken::arbiter {
    include base::firewall
    include standard

    include shinken::arbiter
    shinken::realm { 'All': default => 1 }
    shinken::realm { $realms : }

    $daemons = hiera('monitoring::shinken::daemons', $::daemons)
    create_resources(shinken::arbiter::daemon, $daemons)

    $monitoring_groups = hiera('monitoring::groups')
    $config_dir_defaults = { 'config_dir' => '/etc/shinken/' }
    create_resources(monitoring::group, $monitoring_groups, $config_dir_defaults)

    include facilities
    # TODO: Refactor this (belongs in roles)
    include icinga::nsca::firewall
    # TODO: Refactor this (part role)
    include icinga::nsca::daemon
    # TODO: Rename all of these under monitoring
    include icinga::monitor::wikidata
    include icinga::monitor::ores
    include icinga::monitor::ripeatlas
    include icinga::monitor::legal
    include icinga::monitor::certs
    include icinga::monitor::gsb
    include lvs::monitor
    # TODO: Kill this merge into this role class
    include role::authdns::monitoring
    # TODO: This needs general refactoring
    include network::checks
    # TODO: fix this, we only include it to get the mysql-client package
    include mysql

    interface::add_ip6_mapped { 'main': interface => 'eth0' }
}
