# Common ferm resource for database access. The actual databases are listening on 3306
# and are initially limited to the internal network. More specialised classes
# could grant additional access to other hosts

define profile::mariadb::ferm (
    $port = '3306',
) {
    if $port == '3306' {
        $rule_name = 'mariadb_internal'
    } else {
        $rule_name = "${title}_mariadb_internal"
    }
    ferm::service{ $rule_name:
        proto   => 'tcp',
        port    => $port,
        notrack => true,
        srange  => '$INTERNAL',
    }

    # auxiliary port
    if $port == '3306' {
        $extra_port = 3307
    } else {
        $extra_port = 20 + $port
    }
    ferm::service { "${title}_mariadb_dba":
        proto  => 'tcp',
        port   => $extra_port,
        srange => '$MYSQL_ROOT_CLIENTS',
    }
}
