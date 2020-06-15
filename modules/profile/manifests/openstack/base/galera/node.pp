class profile::openstack::base::galera::node(
    Integer             $server_id             = lookup('profile::openstack::base::galera::server_id'),
    Boolean             $enabled               = lookup('profile::openstack::base::galera::enabled'),
    Array[Stdlib::Fqdn] $openstack_controllers = lookup('profile::openstack::base::openstack_controllers'),
    Array[Stdlib::Fqdn] $designate_hosts       = lookup('profile::openstack::base::designate_hosts'),
    Array[Stdlib::Fqdn] $labweb_hosts          = lookup('profile::openstack::base::labweb_hosts'),
    ) {

    class {'::galera':
        cluster_nodes => $openstack_controllers,
        server_id     => $server_id,
        enabled       => $enabled,
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
                          ${labweb_ips} ${labweb_ip6s}
                          ) proto tcp dport (3306) ACCEPT;",
    }

    # monitoring::service doesn't take a bool
    if $enabled {
        $ensure = 'present'
    }
    else {
        $ensure = 'absent'
    }
    nrpe::monitor_service { 'check_galera_mysqld_process':
        ensure        => $ensure,
        critical      => true,
        description   => 'nova-scheduler process',
        nrpe_command  => "/usr/lib/nagios/plugins/check_procs -c 1:1 -C mysqld'",
        contact_group => 'wmcs-bots,admins',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Portal:Cloud_VPS/Admin/Troubleshooting',
    }

    profile::prometheus::mysqld_exporter_instance { 'wmcs-galera': }
}
