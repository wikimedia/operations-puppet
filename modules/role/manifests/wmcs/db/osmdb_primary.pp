class role::wmcs::db::osmdb_primary {
    system::role { $name: }

    include ::profile::wmcs::services::postgres::osm_primary
}