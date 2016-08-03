class role::prometheus::mysqld_exporter (
    mysql_dc,
    mysql_group,
    mysql_shard,
    mysql_role,
) {
    include passwords::prometheus

    prometheus::mysqld_exporter { 'default':
        client_password => $passwords::prometheus::db_pass,
    }

    $prometheus_nodes = hiera('prometheus_nodes')
    $prometheus_ferm_nodes = join($prometheus_nodes, ' ')

    ferm::service { 'prometheus-mysqld-exporter':
        proto  => 'tcp',
        port   => '9104',
        srange => "@resolve((${prometheus_ferm_nodes}))",
    }

    @@prometheus_mysql_host { $::fqdn:
         mysql_dc    => $mysql_dc,
         mysql_group => $mysql_group,
         mysql_shard => $mysql_shard,
         mysql_role  => $mysql_role,
    }
}
