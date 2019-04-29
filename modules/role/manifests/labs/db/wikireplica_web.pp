class role::labs::db::wikireplica_web {

    system::role { 'labs::db::wikireplica_web':
        description => 'Labs replica database - webrequests',
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
