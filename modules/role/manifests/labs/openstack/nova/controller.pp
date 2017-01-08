# This is nova controller stuff
class role::labs::openstack::nova::controller {
    system::role { $name: }

    require openstack
    include role::labs::openstack::glance::server
    include role::labs::openstack::keystone::server
    include ::openstack::nova::conductor
    include ::openstack::nova::spiceproxy
    include ::openstack::nova::scheduler
    include ::openstack::clientlib
    include role::labs::openstack::nova::common
    $novaconfig = $role::labs::openstack::nova::common::novaconfig
    $designateconfig = hiera_hash('designateconfig', {})

    class { '::openstack::queue_server':
        rabbit_monitor_username => $novaconfig['rabbit_monitor_user'],
        rabbit_monitor_password => $novaconfig['rabbit_monitor_pass'],
    }

    class { '::openstack::adminscripts':
        novaconfig => $novaconfig,
    }

    class { '::openstack::envscripts':
        novaconfig      => $novaconfig,
        designateconfig => $designateconfig,
    }

    class { '::openstack::spreadcheck':
        novaconfig => $novaconfig,
    }

    # TOBE: hiera'd
    $labs_vms = $novaconfig['fixed_range']
    $labs_metal = join(hiera('labs_baremetal_servers', []), ' ')
    $wikitech = ipresolve(hiera('labs_osm_host'),4)
    $horizon = ipresolve(hiera('labs_horizon_host'),4)
    $api_host = ipresolve(hiera('labs_nova_api_host'),4)
    $spare_master = ipresolve(hiera('labs_nova_controller_spare'),4)
    $designate = ipresolve(hiera('labs_designate_hostname'),4)
    $designate_secondary = ipresolve(hiera('labs_designate_hostname_secondary'))
    $monitoring = '208.80.154.14 208.80.153.74 208.80.155.119'
    $labs_nodes = hiera('labs_host_ips')

    # mysql access from iron
    ferm::service { 'mysql_iron':
        proto  => 'tcp',
        port   => '3306',
        srange => '@resolve(iron.wikimedia.org)',
    }

    # mysql monitoring access from tendril (db1011)
    ferm::service { 'mysql_tendril':
        proto  => 'tcp',
        port   => '3306',
        srange => '@resolve(tendril.wikimedia.org)',
    }

    include network::constants
    $prod_networks = join($network::constants::production_networks, ' ')
    $labs_networks = join($network::constants::labs_networks, ' ')

    $fwrules = {
        wikitech_ssh_public => {
            rule  => 'saddr (0.0.0.0/0) proto tcp dport (ssh) ACCEPT;',
        },
        dns_public => {
            rule  => 'saddr (0.0.0.0/0) proto (udp tcp) dport 53 ACCEPT;',
        },
        spice_consoles => {
            rule  => 'saddr (0.0.0.0/0) proto (udp tcp) dport 6082 ACCEPT;',
        },
        keystone_redis_replication => {
            rule  => "saddr (${spare_master}) proto tcp dport (6379) ACCEPT;",
        },
        # keystone admin API only for openstack services that might need it
        keystone_admin => {
            rule  => "saddr (${labs_nodes} ${spare_master} ${api_host}
                             ${designate} ${designate_secondary} ${horizon}
                             ${wikitech}
                             ) proto tcp dport (35357) ACCEPT;",
        },
        # keystone public API for all prod hosts and labs instances
        keystone_public => {
            rule  => "saddr (${prod_networks} ${labs_networks}
                             ) proto tcp dport (5000) ACCEPT;",
        },
        # glance API for all prod hosts and labs instances
        glance => {
            rule  => "saddr (${prod_networks} ${labs_networks}
                             ) proto tcp dport (9292) ACCEPT;",
        },
        mysql_nova => {
            rule  => "saddr ${labs_nodes} proto tcp dport (3306) ACCEPT;",
        },
        beam_nova => {
            rule =>  "saddr ${labs_nodes} proto tcp dport (5672 56918) ACCEPT;",
        },
        rabbit_for_designate => {
            rule =>  "saddr ${designate} proto tcp dport 5672 ACCEPT;",
        },
        rabbit_for_nova_api => {
            rule =>  "saddr ${api_host} proto tcp dport 5672 ACCEPT;",
        },
        glance_api_nova => {
            rule => "saddr ${labs_nodes} proto tcp dport 9292 ACCEPT;",
        },
        salt => {
            rule => "saddr (${labs_vms} ${monitoring}) proto tcp dport (4505 4506) ACCEPT;",
        },
    }

    create_resources (ferm::rule, $fwrules)
}
