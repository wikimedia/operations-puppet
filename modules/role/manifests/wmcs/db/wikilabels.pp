class role::wmcs::db::wikilabels {
    system::role { $name: }

    include ::profile::wmcs::services::postgres::primary
}
