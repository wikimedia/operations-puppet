class role::wmcs::db::osmdb_secondary {
    system::role { $name: }

    include ::profile::wmcs::services::postgres::secondary
}