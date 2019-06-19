class role::labs::db::wikireplica_analytics {

    system::role { 'labs::db::wikireplica_analytics':
        description => 'Labs replica database - analytics',
    }

    include ::profile::standard
    class { '::mariadb::packages_wmf': }
    class { '::mariadb::service': }
    include ::profile::mariadb::monitor
    include ::profile::base::firewall

    include ::profile::labs::db::wikireplica

    include ::passwords::misc::scripts
    include ::role::labs::db::common
    include ::profile::labs::db::views
    include ::role::labs::db::check_private_data
    include ::profile::labs::db::kill_long_running_queries

}
