class role::mariadb::ferm {

    # Common ferm class for database access. The actual databases are listening on 3306
    # and are initially limited to the internal network. More specialised sub classes
    # can grant additional access to other hosts

    ferm::service{ 'mariadb_internal':
        proto   => 'tcp',
        port    => '3306',
        notrack => true,
        srange  => '$INTERNAL',
    }

    # tendril monitoring
    ferm::rule { 'mariadb_monitoring':
        rule => 'saddr @resolve((neon.wikimedia.org)) proto tcp dport (3306) ACCEPT;',
    }

    # for DBA purposes
    ferm::rule { 'mariadb_dba':
        rule => 'saddr @resolve((neon.wikimedia.org db1011.eqiad.wmnet)) proto tcp dport (3307) ACCEPT;',
    }
}

