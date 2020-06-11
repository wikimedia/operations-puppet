# Set up a galera node with mariadb.
#
#  $cluster_nodes: list of fqdns of each node in this cluster
#
#  $server_id: unique integer identifier of this node
#
#
# For initial setup, start with mariadb disabled everywhere.  Then on one node run
#
#  galera_new_cluster
#
# Then start mariadb on each node one at a time, checking status with
#
#  mysql -u root -p -e "show status like 'wsrep_cluster_size'"
#
# After that, change puppet config to enable on all nodes.
#
class galera(
    Array[Stdlib::Fqdn] $cluster_nodes,
    Integer             $server_id,
    Boolean             $enabled,
    Stdlib::Unixpath    $socket          = '/var/run/mysqld/mysqld.sock',
    Stdlib::Unixpath    $basedir         = '/usr',
    Stdlib::Unixpath    $datadir         = '/var/lib/mysql',
    Stdlib::Unixpath    $tmpdir          = '/tmp',
    ) {

    # This will install the latest mariadb + required
    #  galera components.
    package { 'mariadb-server':
        ensure => 'present',
    }

    if $enabled {
        service { 'mysql':
            ensure => running,
            enable => true,
        }
    } else {
        service { 'mysql':
            ensure => stopped,
            enable => false,
        }
    }

    $cluster_node_ips = $cluster_nodes.map |$host| { ipresolve($host, 4) }

    file { '/etc/mysql/mariadb.conf.d/50-server.cnf':
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => template('galera/server.cnf.erb'),
        notify  => Service['mysql'],
    }

    file { '/etc/mysql/mariadb.conf.d/50-mysql-clients.cnf':
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => template('galera/client.cnf.erb'),
        notify  => Service['mysql'],
    }

    file { '/etc/mysql/mariadb.conf.d/50-mysqldump.cnf':
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => template('galera/mysqldump.cnf.erb'),
        notify  => Service['mysql'],
    }
}
