class role::wmcs::db::wikireplicas::web_multiinstance {

    system::role { $name:
        description => 'wikireplica database - web requests, multi-instance',
    }

    include ::profile::standard
    include ::profile::wmcs::db::wikireplicas::mariadb_multiinstance
    include ::profile::base::firewall
    include ::profile::wmcs::db::wikireplicas::views
    include ::profile::mariadb::check_private_data
    include ::profile::wmcs::db::wikireplicas::kill_long_running_queries

}
