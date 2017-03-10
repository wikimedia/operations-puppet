# Common ferm class for database access. The actual databases are listening on 3306
# and are initially limited to the internal network. More specialised sub classes
# can grant additional access to other hosts

class role::mariadb::ferm {
    ferm::service{ 'mariadb_internal':
        proto   => 'tcp',
        port    => '3306',
        notrack => true,
        srange  => '$INTERNAL',
    }

    # for DBA purposes
    ferm::rule { 'mariadb_dba':
        rule => 'saddr @resolve((db1011.eqiad.wmnet)) proto tcp dport (3307) ACCEPT;',
    }
}
