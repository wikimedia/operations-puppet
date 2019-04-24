# ferm define for generic production database access.
# Two ports are opened here:
# The main, production use port, which by default is 3306, but
# could be any other, usually in the 3310-3330 range.
# The extra port, which resides on 3307 by default, and on
# production port + 20 on the others (e.g. 3317 has its extra port on 3337).
# Production port access is, for now, limited to the internal network.
# Extra port is limited to mysql production root hosts (cumin, tendril).
# More specialised classes could grant additional access to other hosts or
# subnetworks.

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
