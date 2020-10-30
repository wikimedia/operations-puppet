class role::wmcs::db::toolsdb_secondary {

    system::role { $name:
        description => 'Cloud user database secondary',
    }

    include ::profile::mariadb::monitor
    include ::role::mariadb::ferm
    include ::profile::wmcs::services::toolsdb_secondary
}
