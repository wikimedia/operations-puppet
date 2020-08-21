class role::wmcs::db::wikireplicas::analytics {

    system::role { $name:
        description => 'Labs replica database - analytics',
    }

    include ::profile::standard
    class { '::mariadb::packages_wmf': }
    class { '::mariadb::service': }
    include ::profile::mariadb::monitor
    include ::profile::base::firewall

    include ::profile::wmcs::db::wikireplicas::mariadb_config
    include ::profile::wmcs::db::scriptconfig
    include ::profile::wmcs::db::wikireplicas::ferm
    include ::profile::wmcs::db::wikireplicas::monitor

    include ::passwords::misc::scripts
    include ::profile::wmcs::db::wikireplicas::views
    include ::profile::mariadb::check_private_data
    include ::profile::wmcs::db::wikireplicas::kill_long_running_queries

}
