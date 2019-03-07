class profile::labs::db::wikireplica::analytics {
    # labsdb1012 is a special db host dedicated only to the Analytics team.
    # Special ferm rules are needed to allow Analytics client to pull data from
    # the host (without affecting the other labsdbs of course).
    ferm::service { 'mysql_labs_db_analytics':
        proto   => 'tcp',
        port    => '3306',
        notrack => true,
        srange  => '$ANALYTICS_NETWORKS',
    }
}
