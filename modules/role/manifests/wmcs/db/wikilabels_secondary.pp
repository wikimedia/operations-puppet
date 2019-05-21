class role::wmcs::db::wikilabels_secondary {
    system::role { $name: }

    include ::profile::wmcs::services::postgres::secondary
}
