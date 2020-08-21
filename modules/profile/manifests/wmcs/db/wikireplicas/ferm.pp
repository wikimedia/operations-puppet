class profile::wmcs::db::wikireplicas::ferm (
    Array[String] $mysql_root_clients = lookup('mysql_root_clients', {default_value =>[]}),
) {
    # mysql monitoring and administration from root clients/tendril
    $mysql_root_clients_str = join($mysql_root_clients, ' ')
    ferm::service { 'mysql_admin_standard':
        proto  => 'tcp',
        port   => '3306',
        srange => "(${mysql_root_clients_str})",
    }
    ferm::service { 'mysql_admin_alternative':
        proto  => 'tcp',
        port   => '3307',
        srange => "(${mysql_root_clients_str})",
    }

    ferm::service { 'mysql_labs_db_proxy':
        proto   => 'tcp',
        port    => '3306',
        notrack => true,
        srange  => '(@resolve((dbproxy1018.eqiad.wmnet)) @resolve((dbproxy1019.eqiad.wmnet)))',
    }

    ferm::service { 'mysql_labs_db_admin':
        proto   => 'tcp',
        port    => '3306',
        notrack => true,
        srange  => '(@resolve((labstore1004.eqiad.wmnet)) @resolve((labstore1005.eqiad.wmnet)))',
    }
}
