# SPDX-License-Identifier: Apache-2.0
class profile::openstack::base::galera::node(
    Integer                       $server_id               = lookup('profile::openstack::base::galera::server_id'),
    Boolean                       $enabled                 = lookup('profile::openstack::base::galera::enabled'),
    Stdlib::Port                  $listen_port             = lookup('profile::openstack::base::galera::listen_port'),
    String                        $prometheus_db_pass      = lookup('profile::openstack::base::galera::prometheus_db_pass'),
    Array[OpenStack::ControlNode] $openstack_control_nodes = lookup('profile::openstack::base::openstack_control_nodes'),
    Array[Stdlib::Fqdn]           $haproxy_nodes           = lookup('profile::openstack::base::haproxy_nodes'),
) {
    $cloudcontrols = $openstack_control_nodes.map |$node| { $node['cloud_private_fqdn'] }
    $this_control_node = $openstack_control_nodes.filter | $entry | {
        $entry['host_fqdn'] == $facts['networking']['fqdn']
    }[0]
    $wsrep_node_name = $this_control_node['cloud_private_fqdn']

    $socket = '/var/run/mysqld/mysqld.sock'
    $datadir = '/srv/sqldata'
    class {'::galera':
        cluster_nodes   => $cloudcontrols,
        server_id       => $server_id,
        enabled         => $enabled,
        port            => $listen_port,
        datadir         => $datadir,
        socket          => $socket,
        wsrep_node_name => $wsrep_node_name,
    }

    # mariadb listen port for debugging/connections/etc
    # 4567, replication
    # 4568, incremental state transfer
    # 4444, state snapshot transfer
    firewall::service { 'galera-cluster-tcp':
        proto  => 'tcp',
        port   => [$listen_port, 4567, 4568, 4444],
        srange => $cloudcontrols,
    }
    firewall::service { 'galera-cluster-udp':
        proto  => 'udp',
        port   => 4567,
        srange => $cloudcontrols,
    }

    # 9990 for the nodecheck service
    firewall::service { 'galera-backend':
        proto  => 'tcp',
        port   => [$listen_port, 9990],
        srange => $haproxy_nodes,
    }

    prometheus::mysqld_exporter { 'default':
        client_password => $prometheus_db_pass,
        client_socket   => $socket,
    } -> service { 'prometheus-mysqld-exporter':
        ensure => 'running',
    }

    openstack::db::project_grants { 'prometheus':
        privs        => 'REPLICATION CLIENT, PROCESS',
        access_hosts => $cloudcontrols + $haproxy_nodes,
        db_name      => '*',
        db_user      => 'prometheus',
        db_pass      => $prometheus_db_pass,
        project_name => 'prometheus',
        require      => Package['prometheus-mysqld-exporter'],
    }

    openstack::db::project_grants { 'prometheus_performance':
        privs        => 'SELECT',
        access_hosts => $cloudcontrols + $haproxy_nodes,
        db_name      => 'performance_schema',
        db_user      => 'prometheus',
        db_pass      => $prometheus_db_pass,
        project_name => 'prometheus',
        require      => Package['prometheus-mysqld-exporter'],
    }

    # nodechecker service -- should be able to run as prometheus user
    # This is a flask app that replies
    # with a 200 or error so we get a real healthcheck for haproxy
    file { '/var/log/nodecheck':
        ensure  => absent,
        recurse => true,
        force   => true,
        purge   => true,
    }
    logrotate::conf { 'nodecheck':
        ensure => absent,
    }
    file { '/usr/local/sbin/galera-nodecheck.py':
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/profile/openstack/base/galera/galera-nodecheck.py',
    }

    systemd::service {'galera_nodecheck':
        ensure  => 'present',
        content => systemd_template('wmcs/galera/galera-nodecheck'),
    }
}
