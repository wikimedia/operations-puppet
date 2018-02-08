# Common ferm resource for database access. The actual databases are listening on 3306
# and are initially limited to the internal network. More specialised classes
# could grant additional access to other hosts

define profile::mariadb::ferm (
    $port = '3306',
) {
    ferm::service{ 'mariadb_internal':
        proto   => 'tcp',
        port    => $port,
        notrack => true,
        srange  => '$INTERNAL',
    }

    # auxiliary port. FIXME for non-standard ports
    if $port == '3306' {
        # for DBA purposes
        ferm::rule { 'mariadb_dba':
            rule => 'saddr ($MYSQL_ROOT_CLIENTS) proto tcp dport (3307) ACCEPT;',
        }
    }
}
