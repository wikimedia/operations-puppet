class role::nova::config {
    include role::nova::config::eqiad
    include role::nova::config::codfw

    if $::realm == 'labs' and $::openstack_site_override != undef {
        $novaconfig = $::openstack_site_override ? {
            'eqiad' => $role::nova::config::eqiad::novaconfig,
            'codfw' => $role::nova::config::codfw::novaconfig,
        }
    } else {
        $novaconfig = $::site ? {
            'eqiad' => $role::nova::config::eqiad::novaconfig,
            'codfw' => $role::nova::config::codfw::novaconfig,
        }
    }
}

class role::nova::config::common {
    require openstack
    include passwords::openstack::nova
    include passwords::openstack::ceilometer
    include passwords::openstack::neutron
    include passwords::labs::rabbitmq

    $commonnovaconfig = {
        db_name                    => 'nova',
        db_user                    => 'nova',
        db_pass                    => $passwords::openstack::nova::nova_db_pass,
        metadata_pass              => $passwords::openstack::nova::nova_metadata_pass,
        rabbit_user                => $passwords::labs::rabbitmq::rabbit_userid,
        rabbit_pass                => $passwords::labs::rabbitmq::rabbit_password,
        neutron_ldap_user_pass     => $passwords::openstack::neutron::neutron_ldap_user_pass,
        ceilometer_user            => $passwords::openstack::ceilometer::db_user,
        ceilometer_pass            => $passwords::openstack::ceilometer::db_pass,
        ceilometer_secret_key      => $passwords::openstack::ceilometer::secret_key,
        ceilometer_db_name         => 'ceilometer',
        my_ip                      => $::ipaddress_eth0,
        use_neutron                => $use_neutron,
        ldap_base_dn               => 'dc=wikimedia,dc=org',
        ldap_user_dn               => 'uid=novaadmin,ou=people,dc=wikimedia,dc=org',
        ldap_user_pass             => $passwords::openstack::nova::nova_ldap_user_pass,
        ldap_proxyagent            => 'cn=proxyagent,ou=profile,dc=wikimedia,dc=org',
        ldap_proxyagent_pass       => $passwords::openstack::nova::nova_ldap_proxyagent_pass,
        controller_mysql_root_pass => $passwords::openstack::nova::controller_mysql_root_pass,
        puppet_db_name             => 'puppet',
        puppet_db_user             => 'puppet',
        puppet_db_pass             => $passwords::openstack::nova::nova_puppet_user_pass,
        # By default, don't allow projects to allocate public IPs; this way we can
        # let users have network admin rights, for firewall rules and such, and can
        # give them public ips by increasing their quota
        quota_floating_ips         => '0',
        libvirt_type => $::realm ? {
            'production' => 'kvm',
            'labs'       => 'qemu',
        },
    }
}

class role::nova::config::codfw inherits role::nova::config::common {
    include role::keystone::config::eqiad

    $nova_controller = hiera('labs_nova_controller')

    $keystoneconfig = $role::keystone::config::eqiad::keystoneconfig
    $controller_hostname = $::realm ? {
        'production' => $nova_controller,
        'labs'       => $nova_controller_hostname ? {
            undef   => $::ipaddress_eth0,
            default => $nova_controller_hostname,
        }
    }
    $controller_address = $::realm ? {
        'production' => ipresolve($nova_controller, 4),
        'labs'       => $nova_controller_ip ? {
            undef   => $::ipaddress_eth0,
            default => $nova_controller_ip,
        }
    }
    $designate_hostname = $::realm ? {
        'production' => 'holmium.wikimedia.org',
        'labs'       => $nova_controller_hostname ? {
            undef   => $::ipaddress_eth0,
            default => $nova_controller_hostname,
        }
    }

    $codfwnovaconfig = {
        db_host            => $controller_hostname,
        dhcp_domain        => 'codfw.wmflabs',
        glance_host        => $controller_hostname,
        rabbit_host        => $controller_hostname,
        cc_host            => $controller_hostname,
        designate_hostname => $designate_hostname,
        network_flat_interface => $::realm ? {
            'production' => 'eth1.1102',
            'labs'       => 'eth0.1118',
        },
        network_flat_tagged_base_interface => $::realm ? {
            'production' => 'eth1',
            'labs'       => 'eth0',
        },
        network_flat_interface_vlan => '1102',
        flat_network_bridge => 'br1102',
        network_public_interface => 'eth0',
        network_host => $::realm ? {
            'production' => '10.64.20.13',
            'labs'       => $nova_network_hostname ? {
                undef   => $::ipaddress_eth0,
                default => $nova_network_hostname,
            }
        },
        api_host => $::realm ? {
            'production' => 'labnet1001.eqiad.wmnet',
            'labs'       => $nova_controller_hostname ? {
                undef   => $::ipaddress_eth0,
                default => $nova_controller_hostname,
            }
        },
        api_ip => $::realm ? {
            'production' => '10.64.20.13',
            'labs'       => $nova_controller_ip ? {
                undef   => $::ipaddress_eth0,
                default => $nova_controller_ip,
            }
        },
        fixed_range => $::realm ? {
            'production' => '10.68.16.0/21',
            'labs'       => '192.168.0.0/21',
        },
        dhcp_start => $::realm ? {
            'production' => '10.68.16.4',
            'labs'       => '192.168.0.4',
        },
        network_public_ip => $::realm ? {
            'production' => '208.80.155.255',
            'labs'       => $nova_network_ip ? {
                undef   => $::ipaddress_eth0,
                default => $nova_network_ip,
            }
        },
        dmz_cidr => $::realm ? {
            'production' => '208.80.155.0/22,10.0.0.0/8',
            'labs'       => '10.4.0.0/21',
        },
        auth_uri => $::realm ? {
            'production' => "http://${nova_controller}:5000",
            'labs'       => 'http://localhost:5000',
        },
        controller_hostname    => $controller_hostname,
        controller_address     => $controller_address,
        ldap_host              => $controller_hostname,
        puppet_host            => $controller_hostname,
        puppet_db_host         => $controller_hostname,
        live_migration_uri     => 'qemu://%s.codfw.wmnet/system?pkipath=/var/lib/nova',
        zone                   => 'codfw',
        keystone_admin_token   => $keystoneconfig['admin_token'],
        keystone_auth_host     => $keystoneconfig['bind_ip'],
        keystone_auth_protocol => $keystoneconfig['auth_protocol'],
        keystone_auth_port     => $keystoneconfig['auth_port'],
    }

    $novaconfig = merge( $codfwnovaconfig, $commonnovaconfig )
}

class role::nova::config::eqiad inherits role::nova::config::common {
    include role::keystone::config::eqiad

    $nova_controller = hiera('labs_nova_controller')

    $keystoneconfig = $role::keystone::config::eqiad::keystoneconfig
    $controller_hostname = $::realm ? {
        'production' => $nova_controller,
        'labs'       => $nova_controller_hostname ? {
            undef   => $::ipaddress_eth0,
            default => $nova_controller_hostname,
        }
    }
    $designate_hostname = $::realm ? {
        'production' => 'holmium.wikimedia.org',
        'labs'       => $nova_controller_hostname ? {
            undef   => $::ipaddress_eth0,
            default => $nova_controller_hostname,
        }
    }
    $controller_address = $::realm ? {
        'production' => ipresolve($nova_controller,4),
        'labs'       => $nova_controller_ip ? {
            undef   => $::ipaddress_eth0,
            default => $nova_controller_ip,
        }
    }

    $eqiadnovaconfig = {
        db_host            => 'm5-master.eqiad.wmnet',
        dhcp_domain        => 'eqiad.wmflabs',
        glance_host        => $controller_hostname,
        rabbit_host        => $controller_hostname,
        cc_host            => $controller_hostname,
        designate_hostname => $designate_hostname,
        network_flat_interface => $::realm ? {
            'production' => 'eth1.1102',
            'labs'       => 'eth0.1118',
        },
        network_flat_tagged_base_interface => $::realm ? {
            'production' => 'eth1',
            'labs'       => 'eth0',
        },
        network_flat_interface_vlan => '1102',
        flat_network_bridge => 'br1102',
        network_public_interface => 'eth0',
        network_host => $::realm ? {
            'production' => '10.64.20.13',
            'labs'       => $nova_network_hostname ? {
                undef   => $::ipaddress_eth0,
                default => $nova_network_hostname,
            }
        },
        api_host => $::realm ? {
            'production' => 'labnet1001.eqiad.wmnet',
            'labs'       => $nova_controller_hostname ? {
                undef   => $::ipaddress_eth0,
                default => $nova_controller_hostname,
            }
        },
        api_ip => $::realm ? {
            'production' => '10.64.20.13',
            'labs'       => $nova_controller_ip ? {
                undef   => $::ipaddress_eth0,
                default => $nova_controller_ip,
            }
        },
        fixed_range => $::realm ? {
            'production' => '10.68.16.0/21',
            'labs'       => '192.168.0.0/21',
        },
        dhcp_start => $::realm ? {
            'production' => '10.68.16.4',
            'labs'       => '192.168.0.4',
        },
        network_public_ip => $::realm ? {
            'production' => '208.80.155.255',
            'labs'       => $nova_network_ip ? {
                undef   => $::ipaddress_eth0,
                default => $nova_network_ip,
            }
        },
        dmz_cidr => $::realm ? {
            'production' => '208.80.155.0/22,10.0.0.0/8',
            'labs'       => '10.4.0.0/21',
        },
        auth_uri => $::realm ? {
            'production' => "http://${nova_controller}:5000",
            'labs'       => 'http://localhost:5000',
        },
        controller_hostname    => $controller_hostname,
        controller_address     => $controller_address,
        ldap_host              => $controller_hostname,
        puppet_host            => $controller_hostname,
        puppet_db_host         => $controller_hostname,
        live_migration_uri     => 'qemu://%s.eqiad.wmnet/system?pkipath=/var/lib/nova',
        zone                   => 'eqiad',
        keystone_admin_token   => $keystoneconfig['admin_token'],
        keystone_auth_host     => $keystoneconfig['bind_ip'],
        keystone_auth_protocol => $keystoneconfig['auth_protocol'],
        keystone_auth_port     => $keystoneconfig['auth_port'],
    }
    if ( $::hostname == 'labnet1001' ) {
        $networkconfig = {
            network_flat_interface =>  'eth1.1102',
            network_flat_tagged_base_interface => 'eth1',
        }
        $novaconfig = merge( $eqiadnovaconfig, $commonnovaconfig, $networkconfig )
    } else {
        $novaconfig = merge( $eqiadnovaconfig, $commonnovaconfig )
    }
}

class role::nova::common {
    include role::nova::config
    $novaconfig = $role::nova::config::novaconfig

    include passwords::misc::scripts

    $status_wiki_host_master = $::realm ? {
            'production' => 'wikitech.wikimedia.org',
            'labs'       => $::osm_hostname,
    }

    class { 'openstack::common':
        novaconfig                       => $novaconfig,
        instance_status_wiki_host        => $status_wiki_host_master,
        instance_status_wiki_domain      => 'labs',
        instance_status_wiki_page_prefix => 'Nova_Resource:',
        instance_status_wiki_region      => $::site,
        instance_status_dns_domain       => "${::site}.wmflabs",
        instance_status_wiki_user        => $passwords::misc::scripts::wikinotifier_user,
        instance_status_wiki_pass        => $passwords::misc::scripts::wikinotifier_pass,
    }

    include role::nova::wikiupdates
}

# This is the wikitech UI
class role::nova::manager {
    include role::nova::config
    $novaconfig = $role::nova::config::novaconfig

    case $::realm {
        'labs': {
            $certificate = 'star.wmflabs'
        }
        'production': {
            $certificate = 'wikitech.wikimedia.org'
        }
        default: {
            fail('unknown realm, should be labs or production')
        }
    }

    sslcert::std_cert { $certificate: }

    $ssl_settings = ssl_ciphersuite('apache-2.2', 'compat', '365')

    ferm::service { 'wikitech_http':
        proto => 'tcp',
        port  => '80',
    }

    ferm::service { 'wikitech_https':
        proto => 'tcp',
        port  => '443',
    }

    # allow ssh from deployment hosts
    ferm::rule { 'deployment-ssh':
        ensure => present,
        rule   => 'proto tcp dport ssh saddr $DEPLOYMENT_HOSTS ACCEPT;',
    }

    class { 'openstack::openstack-manager':
        novaconfig  => $novaconfig,
        certificate => $certificate,
    }

    # T89323
    monitoring::service { 'wikitech-static-sync':
        description   => 'are wikitech and wt-static in sync',
        check_command => 'check_wikitech_static',
    }

    include ::nutcracker::monitoring
    include ::mediawiki::packages::php5
    include ::mediawiki::cgroup
    include ::scap::scripts

    class { '::nutcracker':
        mbuf_size => '64k',
        pools     => {
            'memcached' => {
                auto_eject_hosts     => true,
                distribution         => 'ketama',
                hash                 => 'md5',
                listen               => '127.0.0.1:11212',
                preconnect           => true,
                server_connections   => 2,
                server_failure_limit => 3,
                timeout              => 250,
                servers              => [
                    '127.0.0.1:11000:1',
                ],
            },
        },
    }
}

# This is nova controller stuff
class role::nova::controller {
    require openstack
    include role::nova::config
    $novaconfig = $role::nova::config::novaconfig

    include role::keystone::config::eqiad
    include role::glance::config::eqiad
    include role::nova::wikiupdates

    if $::realm == 'labs' and $::openstack_site_override != undef {
        $glanceconfig = $::openstack_site_override ? {
            'eqiad' => $role::glance::config::eqiad::glanceconfig,
        }
        $keystoneconfig = $::openstack_site_override ? {
            'eqiad' => $role::keystone::config::eqiad::keystoneconfig,
        }
    } else {
        $glanceconfig = $::site ? {
            'eqiad' => $role::glance::config::eqiad::glanceconfig,
        }
        $keystoneconfig = $::site ? {
            'eqiad' => $role::keystone::config::eqiad::keystoneconfig,
        }
    }

    include role::nova::common

    class { 'openstack::nova::conductor':
        novaconfig        => $novaconfig,
    }
    class { 'openstack::nova::scheduler':
        novaconfig        => $novaconfig,
    }
    class { 'openstack::glance::service':
        glanceconfig      => $glanceconfig,
    }
    class { 'openstack::queue-server':
        novaconfig        => $novaconfig,
    }
    class { 'role::keystone::server':
        glanceconfig => $glanceconfig,
    }

    if $::realm == 'production' {
        class { 'openstack::controller_firewall': }
        class { 'role::puppet::server::labs': }
    }

    class { 'openstack::adminscripts':
        novaconfig => $novaconfig
    }

    class { 'openstack::spreadcheck':
        novaconfig => $novaconfig
    }
}

class role::nova::api {
    require openstack
    include role::nova::config
    $novaconfig = $role::nova::config::novaconfig

    include role::nova::common

    class { 'openstack::nova::api':
        novaconfig        => $novaconfig,
    }
}

class role::nova::network::bonding {
    interface::aggregate { 'bond1':
        orig_interface => 'eth1',
        members        => [ 'eth1', 'eth2', 'eth3' ],
    }
}

class role::nova::network {
    require openstack
    include role::nova::config
    $novaconfig = $role::nova::config::novaconfig

    include role::nova::common
    include role::nova::wikiupdates

    if ($::realm == production) {
        $site_address = $::site ? {
            'eqiad' => '208.80.155.255',
        }

        interface::ip { 'openstack::network_service_public_dynamic_snat':
            interface => 'lo',
            address   => $site_address,
        }
    }

    interface::tagged { $novaconfig['network_flat_interface']:
        base_interface => $novaconfig['network_flat_tagged_base_interface'],
        vlan_id        => $novaconfig['network_flat_interface_vlan'],
        method         => 'manual',
        up             => 'ip link set $IFACE up',
        down           => 'ip link set $IFACE down',
    }

    class { 'openstack::nova::network':
        novaconfig        => $novaconfig,
    }

    diamond::collector::conntrack { 'conntrack_collector': }

    # The current maximum is 262144; the threshold should be set
    # to a faction of *.conntrack_max rather than a literal here
    # but graphite_threshold doesn't support that.
    monitoring::graphite_threshold { 'conntrack_saturated':
        description => 'Connection tracking saturation',
        metric      => "servers.${::hostname}.ConntrackCollector.network.netfilter.conntrack_count",
        from        => '5min',
        warning     => '241664', # (~90%)
        critical    => '258048', # (~98%)
        percentage  => '1',
    }

}

class role::nova::wikiupdates {
    require openstack
    if $::realm == 'production' {
        if ! defined(Package['python-mwclient']) {
            package { 'python-mwclient':
                ensure => latest,
            }
        }
    }

    package { 'python-openstack-wikistatus':
        ensure  => installed,
        require => Package['python-mwclient'],
    }

    # Cleanup.  Can be removed by the time you are reading this.
    file { '/usr/local/lib/python2.6/dist-packages/wikinotifier.py':
        ensure => absent,
    }

    # Cleanup.  Can be removed by the time you are reading this.
    file { '/usr/local/lib/python2.7/dist-packages/wikinotifier.py':
        ensure => absent,
    }
}

class role::nova::compute($instance_dev='/dev/md1') {
    require openstack
    include role::nova::config
    $novaconfig = $role::nova::config::novaconfig

    include role::nova::common
    ganglia::plugin::python {'diskstat': }

    system::role { 'role::nova::compute':
        ensure      => 'present',
        description => 'openstack nova compute node',
    }

    # Neutron roles configure their own interfaces.
    if ( $use_neutron == false ) {
        interface::tagged { $novaconfig['network_flat_interface']:
            base_interface => $novaconfig['network_flat_tagged_base_interface'],
            vlan_id        => $novaconfig['network_flat_interface_vlan'],
            method         => 'manual',
            up             => 'ip link set $IFACE up',
            down           => 'ip link set $IFACE down',
        }
    }

    class { 'openstack::nova::compute':
        novaconfig        => $novaconfig,
    }

    if $::realm == 'production' {
        mount { '/var/lib/nova/instances':
            ensure  => mounted,
            device  => $instance_dev,
            fstype  => 'xfs',
            options => 'defaults',
        }

        file { '/var/lib/nova/instances':
            ensure  => directory,
            owner   => 'nova',
            group   => 'nova',
            require => Mount['/var/lib/nova/instances'],
        }
    }

    if os_version('debian >= jessie || ubuntu >= trusty') {
        # Some older VMs have a hardcoded path to the emulator
        #  binary, /usr/bin/kvm.  Since the kvm/qemu reorg,
        #  new distros don't create a kvm binary.  We can safely
        #  alias kvm to qemu-system-x86_64 which keeps those old
        #  instances happy.
        file { '/usr/bin/kvm':
            ensure => link,
            target => '/usr/bin/qemu-system-x86_64',
        }
    }
}

# global icinga hostgroups for virt/labs hosts
@monitoring::group { 'virt_eqiad': description => 'eqiad virt servers' }
@monitoring::group { 'virt_esams': description => 'esams virt servers' }
@monitoring::group { 'virt_codfw': description => 'codfw virt servers' }
@monitoring::group { 'virt_ulsfo': description => 'ulsfo virt servers' }
