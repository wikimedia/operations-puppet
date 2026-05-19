# firewall define for generic production database access.
# Two ports are opened here:
# The main, production use port, which by default is 3306, but
# could be any other, usually in the 3310-3329 or 3350-3370 range.
# The extra port, which resides on 3307 by default, and on
# production port + 20 on the others (e.g. 3317 has its extra port on 3337).
# Production port access is, for now, limited to the internal network.
# Extra port is limited to mysql production root hosts (cumin, tendril).
# More specialised classes could grant additional access to other hosts or
# subnetworks.

define profile::mariadb::firewall (
    Stdlib::Port $port = 3306,
) {
    $prefix = $port ? {
        3306    => '',
        default => "${title}_",
    }

    firewall::service{ "${prefix}mariadb_internal":
        proto    => 'tcp',
        port     => $port,
        notrack  => true,
        src_sets => ['INTERNAL'],
    }

    firewall::service{ "${prefix}orchestrator":
        proto   => 'tcp',
        port    => [$port],
        notrack => true,
        srange  => ['dborch1001.wikimedia.org', 'dborch1002.wikimedia.org', 'dborch1003.eqiad.wmnet'],
    }
    # auxiliary port
    if $port == 3306 {
        $extra_port = 3307
    } else {
        $extra_port = 20 + $port
    }
    firewall::service { "${title}_mariadb_dba":
        proto    => 'tcp',
        port     => $extra_port,
        src_sets => ['MYSQL_ROOT_CLIENTS'],
    }
}
