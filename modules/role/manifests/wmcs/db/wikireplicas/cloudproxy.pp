class role::wmcs::db::wikireplicas::cloudproxy {
    system::role { $name: }

    include profile::wmcs::db::wikireplicas::proxy
}
