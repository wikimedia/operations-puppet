class profile::wmcs::db::wikireplicas::dedicated::analytics (
    Hash[String, Stdlib::Datasize] $instances = lookup('profile::wmcs::db::wikireplicas::mariadb_multiinstance::instances'),
    Hash[String, Stdlib::Port] $section_ports = lookup('profile::mariadb::section_ports')
) {
    # an-redacteddb1001 is a special db host dedicated only to the Data Platform team.
    # Special ferm rules are needed to allow Analytics clients to pull data from
    # the host.
    $instances.each |$section, $buffer_pool| {
        $port = $section_ports[$section]

        ferm::service { "mysql_labs_db_analytics_${section}":
            proto   => 'tcp',
            port    => $port,
            notrack => true,
            srange  => '$ANALYTICS_NETWORKS',
        }
    }
}
