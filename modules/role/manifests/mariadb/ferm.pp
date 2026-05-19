# Common ferm class for database access. The actual databases are listening on 3306
# and are initially limited to the internal network. More specialised sub classes
# can grant additional access to other hosts

class role::mariadb::ferm {
    firewall::service{ 'mariadb_internal':
        proto    => 'tcp',
        port     => 3306,
        notrack  => true,
        src_sets => ['INTERNAL'],
    }

    firewall::service{ 'orchestrator':
        proto   => 'tcp',
        port    => 3306,
        notrack => true,
        srange  => ['dborch1002.wikimedia.org', 'dborch1003.eqiad.wmnet'],
    }

    # for DBA purposes
    firewall::service{ 'mariadb_dba':
        proto    => 'tcp',
        port     => 3307,
        src_sets => ['MYSQL_ROOT_CLIENTS'],
    }
}
