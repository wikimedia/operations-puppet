class role::wmcs::db::toolsdb_primary {
    system::role { $name: }

    include ::profile::mariadb::monitor
    include ::profile::wmcs::services::toolsdb_primary
}
