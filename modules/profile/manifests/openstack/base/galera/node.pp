class profile::openstack::base::galera::node(
    Integer                $server_id              = lookup('profile::openstack::base::galera::server_id'),
    Boolean                $enabled                = lookup('profile::openstack::base::galera::enabled'),
    Stdlib::Port           $listen_port            = lookup('profile::openstack::base::galera::listen_port'),
    String                 $prometheus_db_pass     = lookup('profile::openstack::base::galera::prometheus_db_pass'),
    Array[Stdlib::Fqdn]    $openstack_controllers  = lookup('profile::openstack::base::openstack_controllers'),
    Array[Stdlib::Fqdn]    $designate_hosts        = lookup('profile::openstack::base::designate_hosts'),
    Array[Stdlib::Fqdn]    $labweb_hosts           = lookup('profile::openstack::base::labweb_hosts'),
    Array[Stdlib::Fqdn]    $cinder_backup_nodes    = lookup('profile::openstack::base::cinder::backup::nodes'),
    ) {

    $socket = '/var/run/mysqld/mysqld.sock'
    $datadir = '/srv/sqldata'
    file { $datadir:
        ensure => directory,
        owner  => 'mysql',
        group  => 'mysql',
        mode   => '0755',
    }

    class {'::galera':
        cluster_nodes => $openstack_controllers,
        server_id     => $server_id,
        enabled       => $enabled,
        port          => $listen_port,
        datadir       => $datadir,
        socket        => $socket,
    }

    $cluster_node_ips = inline_template("@resolve((<%= @openstack_controllers.join(' ') %>))")
    $cluster_node_ips_v6 = inline_template("@resolve((<%= @openstack_controllers.join(' ') %>), AAAA)")
    # Galera replication
    ferm::rule{'galera_replication':
        ensure => 'present',
        rule   => "saddr (${cluster_node_ips} ${cluster_node_ips_v6}) proto tcp dport 4567 ACCEPT;",
    }

    # incremental state transfer
    ferm::rule{'galera_state_transfer':
        ensure => 'present',
        rule   => "saddr (${cluster_node_ips} ${cluster_node_ips_v6}) proto tcp dport 4568 ACCEPT;",
    }

    # state snapshot transfer
    ferm::rule{'galera_snapshot_transfer':
        ensure => 'present',
        rule   => "saddr (${cluster_node_ips} ${cluster_node_ips_v6}) proto tcp dport 4444 ACCEPT;",
    }

    $labweb_ips = inline_template("@resolve((<%= @labweb_hosts.join(' ') %>))")
    $labweb_ip6s = inline_template("@resolve((<%= @labweb_hosts.join(' ') %>), AAAA)")

    # Database access from each db node, HA-proxy, designate, web hosts
    ferm::rule{'galera_db_access':
        ensure => 'present',
        rule   => "saddr (@resolve((${join($openstack_controllers,' ')}))
                          @resolve((${join($openstack_controllers,' ')}), AAAA)
                          @resolve((${join($designate_hosts,' ')}))
                          @resolve((${join($designate_hosts,' ')}), AAAA)
                          @resolve((${join($cinder_backup_nodes,' ')}))
                          @resolve((${join($cinder_backup_nodes,' ')}), AAAA)
                          ${labweb_ips} ${labweb_ip6s}
                          ) proto tcp dport (3306) ACCEPT;",
    }

    $galera_proc = debian::codename::ge('bullseye').bool2str('mariadbd', 'mysqld')

    nrpe::monitor_service { "check_galera_${galera_proc}_process":
        ensure        => $enabled.bool2str('present', 'absent'),
        description   => 'mysql (galera) process',
        nrpe_command  => "/usr/lib/nagios/plugins/check_procs -c 1:1 -C ${galera_proc}",
        contact_group => 'wmcs-bots',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Portal:Cloud_VPS/Admin/Troubleshooting',
    }

    prometheus::mysqld_exporter { 'default':
        client_password => $prometheus_db_pass,
        client_socket   => $socket,
    } -> service { 'prometheus-mysqld-exporter':
        ensure => 'running',
    }

    openstack::db::project_grants { 'prometheus':
        privs        => 'REPLICATION CLIENT, PROCESS',
        access_hosts => $openstack_controllers,
        db_name      => '*',
        db_user      => 'prometheus',
        db_pass      => $prometheus_db_pass,
        project_name => 'prometheus',
    }

    openstack::db::project_grants { 'prometheus_performance':
        privs        => 'SELECT',
        access_hosts => $openstack_controllers,
        db_name      => 'performance_schema',
        db_user      => 'prometheus',
        db_pass      => $prometheus_db_pass,
        project_name => 'prometheus',
    }

    # nodechecker service -- should be able to run as prometheus user
    # This is a simple shellscript running on a systemd socket that replies
    # with a 200 or error so we get a real healthcheck for haproxy
    ferm::rule{'galera_nodecheck':
        ensure => 'present',
        rule   => "saddr (${cluster_node_ips} ${cluster_node_ips_v6}) proto tcp dport 9990 ACCEPT;",
    }
    file { '/var/log/nodecheck':
        ensure => directory,
        owner  => 'prometheus',
        group  => 'prometheus',
        mode   => '0755',
    }
    file { '/usr/local/sbin/nodecheck.sh':
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/profile/openstack/base/galera/nodecheck.sh',
    }
    file { '/usr/local/sbin/nodecheck.py':
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/profile/openstack/base/galera/nodecheck.py',
    }
    file { '/lib/systemd/system/nodecheck@.service':
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/profile/openstack/base/galera/nodecheck.systemd.service',
    }
    file { '/lib/systemd/system/nodecheck.socket':
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/profile/openstack/base/galera/nodecheck.systemd.socket',
        notify => Exec['nodecheck-enable'],
    }
    # We aren't enabling the service. It's the socket we want.
    exec { 'nodecheck-enable':
        command     => 'systemctl daemon-reload; systemctl enable nodecheck.socket; systemctl restart nodecheck.socket',
        path        => [ '/usr/bin', '/bin', '/usr/sbin' ],
        refreshonly => true,
    }

    systemd::service {'galera_nodecheck':
        ensure  => 'present',
        content => systemd_template('wmcs/galera/galera-nodecheck'),
    }
}
